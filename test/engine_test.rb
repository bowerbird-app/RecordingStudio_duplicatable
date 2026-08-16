# frozen_string_literal: true

require "test_helper"

class EngineTest < Minitest::Test
  def setup
    @original_configuration = RecordingStudioDuplicatable.instance_variable_get(:@configuration)
    RecordingStudioDuplicatable.instance_variable_set(:@configuration, RecordingStudioDuplicatable::Configuration.new)
    @recording_studio_defined = Object.const_defined?(:RecordingStudio)
    @original_recording_studio = RecordingStudio if @recording_studio_defined
  end

  def teardown
    RecordingStudioDuplicatable.configuration.hooks.clear!
    RecordingStudioDuplicatable.instance_variable_set(:@configuration, @original_configuration)

    if @recording_studio_defined
      Object.send(:remove_const, :RecordingStudio) if Object.const_defined?(:RecordingStudio)
      Object.const_set(:RecordingStudio, @original_recording_studio)
    elsif Object.const_defined?(:RecordingStudio)
      Object.send(:remove_const, :RecordingStudio)
    end
  end

  def test_before_and_after_initialize_initializers_run_hooks
    before_called = false
    after_called = false

    RecordingStudioDuplicatable.configuration.hooks.before_initialize { |_engine| before_called = true }
    RecordingStudioDuplicatable.configuration.hooks.after_initialize { |_engine| after_called = true }

    find_initializer("recording_studio_duplicatable.before_initialize").block.call(Object.new)
    find_initializer("recording_studio_duplicatable.after_initialize").block.call(Object.new)

    assert before_called
    assert after_called
  end

  def test_load_config_merges_config_sources_and_runs_on_configuration_hook
    hook_called = false
    hook_payload = nil
    RecordingStudioDuplicatable.configuration.hooks.on_configuration do |cfg|
      hook_called = true
      hook_payload = cfg
    end

    xcfg = Struct.new(:recording_studio_duplicatable).new({ duplication_suffix: " [dup]" })
    app_config = Struct.new(:x).new(xcfg)
    app = Struct.new(:config) do
      def config_for(_name)
        { duplication_prefix: "Copy: " }
      end
    end.new(app_config)

    find_initializer("recording_studio_duplicatable.load_config").block.call(app)

    assert hook_called
    assert_equal RecordingStudioDuplicatable.configuration, hook_payload
    assert_equal "Copy: ", RecordingStudioDuplicatable.configuration.duplication_prefix
    assert_equal " [dup]", RecordingStudioDuplicatable.configuration.duplication_suffix
  end

  def test_load_config_handles_errors_and_each_pair_fallback
    pair_config = Class.new do
      def each_pair
        yield(:duplication_suffix, " via x config")
      end
    end.new

    xcfg = Struct.new(:recording_studio_duplicatable).new(pair_config)
    app_config = Struct.new(:x).new(xcfg)

    app = Struct.new(:config) do
      def config_for(_name)
        raise "missing file"
      end
    end.new(app_config)

    find_initializer("recording_studio_duplicatable.load_config").block.call(app)

    assert_equal " via x config", RecordingStudioDuplicatable.configuration.duplication_suffix
  end

  def test_load_config_swallow_each_pair_errors
    bad_pair_config = Class.new do
      def each_pair
        raise "bad pair"
      end
    end.new

    xcfg = Struct.new(:recording_studio_duplicatable).new(bad_pair_config)
    app_config = Struct.new(:x).new(xcfg)
    app = Struct.new(:config) do
      def config_for(_name)
        { duplication_prefix: "[copy] " }
      end
    end.new(app_config)

    # Should not raise even if xcfg.each_pair fails.
    find_initializer("recording_studio_duplicatable.load_config").block.call(app)

    assert_equal "[copy] ", RecordingStudioDuplicatable.configuration.duplication_prefix
  end

  def test_apply_extension_initializers_register_active_support_on_load_callbacks
    to_prepare_blocks = []
    config_stub = Object.new
    config_stub.define_singleton_method(:to_prepare) do |&block|
      to_prepare_blocks << block
    end

    RecordingStudioDuplicatable::Engine.stub(:config, config_stub) do
      find_initializer("recording_studio_duplicatable.apply_model_extensions").block.call
      find_initializer("recording_studio_duplicatable.apply_controller_extensions").block.call
    end

    assert_equal 2, to_prepare_blocks.size
  end

  def test_api_initializer_registers_the_duplicate_capability_action
    registered = false

    RecordingStudioDuplicatable::Api.stub(:register_capability_action!, -> { registered = true }) do
      find_initializer("recording_studio_duplicatable.register_recording_studio_api_action").block.call
    end

    assert registered
  end

  def test_capability_initializer_registers_and_applies_capabilities
    recording_class = Class.new
    recording_studio = build_recording_studio_stub(recording_class: recording_class)

    swap_recording_studio_constant(recording_studio)

    find_initializer("recording_studio_duplicatable.apply_recording_studio_capabilities").block.call

    assert_equal(
      RecordingStudioDuplicatable::Capabilities::Duplicatable::RecordingMethods,
      recording_studio.registered_capabilities[:duplicatable][:mod]
    )
    assert_equal "recording_studio_duplicatable",
                 recording_studio.registered_capabilities[:duplicatable][:source]
    assert_includes recording_class.included_modules,
                    RecordingStudioDuplicatable::Capabilities::Duplicatable::RecordingMethods
  end

  def test_model_extension_prepare_block_reapplies_recording_studio_capabilities
    to_prepare_blocks = []
    config_stub = Object.new
    config_stub.define_singleton_method(:to_prepare) do |&block|
      to_prepare_blocks << block
    end

    recording_class = Class.new
    recording_studio = build_recording_studio_stub(recording_class: recording_class)
    swap_recording_studio_constant(recording_studio)

    RecordingStudioDuplicatable::Engine.stub(:config, config_stub) do
      find_initializer("recording_studio_duplicatable.apply_model_extensions").block.call
    end

    assert_equal 1, to_prepare_blocks.size

    to_prepare_blocks.first.call

    assert_includes recording_class.included_modules,
                    RecordingStudioDuplicatable::Capabilities::Duplicatable::RecordingMethods
  end

  def test_apply_model_extensions_adds_registered_methods_once
    model_class = Class.new do
      def self.name
        "ExampleRecord"
      end
    end

    RecordingStudioDuplicatable.configuration.hooks.extend_model(:ExampleRecord) do
      def template_extension_method
        :applied
      end
    end

    RecordingStudioDuplicatable::Engine.apply_model_extensions(model_class)
    RecordingStudioDuplicatable::Engine.apply_model_extensions(model_class)

    instance = model_class.new
    assert_equal :applied, instance.template_extension_method
  end

  def test_apply_controller_extensions_matches_demodulized_name
    controller_class = Class.new do
      def self.name
        "Admin::DashboardController"
      end
    end

    RecordingStudioDuplicatable.configuration.hooks.extend_controller(:DashboardController) do
      def template_controller_extension
        :applied
      end
    end

    RecordingStudioDuplicatable::Engine.apply_controller_extensions(controller_class)

    instance = controller_class.new
    assert_equal :applied, instance.template_controller_extension
  end

  private

  def build_recording_studio_stub(recording_class:)
    Module.new do
      @registered_capabilities = {}

      define_singleton_method(:registered_capabilities) { @registered_capabilities }
      const_set(:Recording, recording_class)

      define_singleton_method(:register_capability) do |name, mod = nil, **options|
        @registered_capabilities[name.to_sym] = { mod: mod, **options }
      end

      define_singleton_method(:apply_capabilities!) do
        @registered_capabilities.each_value do |registration|
          mod = registration[:mod]
          next unless mod
          next if const_get(:Recording).included_modules.include?(mod)

          const_get(:Recording).include(mod)
        end
      end
    end
  end

  def swap_recording_studio_constant(mod)
    Object.send(:remove_const, :RecordingStudio) if Object.const_defined?(:RecordingStudio)
    Object.const_set(:RecordingStudio, mod)
  end

  def find_initializer(name)
    RecordingStudioDuplicatable::Engine.initializers.find { |initializer| initializer.name == name }
  end
end
