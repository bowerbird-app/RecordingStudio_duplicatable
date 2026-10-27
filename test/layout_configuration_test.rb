# frozen_string_literal: true

require "test_helper"
require "action_controller"

class RecordingStudioDuplicatableLayoutProbeController < ActionController::Base
  recording_studio_layout { RecordingStudioDuplicatable.configuration.layout }
end

class LayoutConfigurationTest < Minitest::Test
  def setup
    @duplicatable = RecordingStudioDuplicatable.configuration
    @core = RecordingStudio.configuration
    @original_duplicatable_layout = @duplicatable.layout
    @original_core_layout = @core.layout
  end

  def teardown
    @duplicatable.layout = @original_duplicatable_layout
    @core.layout = @original_core_layout
  end

  def test_layout_defaults_to_nil
    configuration = RecordingStudioDuplicatable::Configuration.new

    assert_nil configuration.layout
  end

  def test_nil_layout_falls_through_to_recording_studio_configuration_then_default
    @duplicatable.layout = nil
    @core.layout = "host_layout"

    assert_equal "host_layout", resolved_layout

    @core.layout = nil

    assert_equal "recording_studio/default_layout", resolved_layout
  end

  def test_string_layout_is_used_as_the_layout_name
    @duplicatable.layout = "admin"

    assert_equal "admin", @duplicatable.layout
    assert_equal "admin", resolved_layout
  end

  def test_false_layout_skips_the_layout
    @duplicatable.layout = false
    @core.layout = "host_layout"

    assert_equal false, @duplicatable.layout
    assert_equal false, resolved_layout
  end

  def test_keyword_callable_receives_the_controller
    seen = nil
    @duplicatable.layout = lambda do |controller:|
      seen = controller
      "probe_layout"
    end

    assert_equal "probe_layout", resolved_layout
    assert_instance_of RecordingStudioDuplicatableLayoutProbeController, seen
  end

  def test_invalid_layout_values_raise_argument_error
    assert_raises(ArgumentError) { @duplicatable.layout = "" }
    assert_raises(ArgumentError) { @duplicatable.layout = 1 }
    assert_raises(ArgumentError) { @duplicatable.layout = ->(controller) { controller } }
  end

  def test_controllers_do_not_hardcode_recording_studio_layouts
    root = File.expand_path("..", __dir__)

    assert_empty RecordingStudio::Layout.hardcoded_layout_paths(root)
    assert_empty RecordingStudio::Layout.hardcoded_layout_paths(File.join(root, "test", "dummy"))
  end

  private

  def resolved_layout
    RecordingStudioDuplicatableLayoutProbeController.new.recording_studio_resolved_layout
  end
end
