# frozen_string_literal: true

# Load RecordingStudio stubs before test_helper so gem_template finds them at
# require time. Guard with `unless defined?` so the stubs defined in
# duplicatable_test.rb are reused when both test files run in the same process.
unless defined?(RecordingStudio)
  module RecordingStudio
    class AccessDenied < StandardError; end
    class CapabilityDisabled < StandardError; end

    module Capability
      private

      def assert_capability!(_name) = nil
    end

    module Services
      module AccessCheck
        def self.allowed?(actor:, recording:, role:) = true
      end
    end

    REGISTERED_CAPABILITIES  = {}
    ENABLED_CAPABILITIES     = Hash.new { |h, k| h[k] = [] }
    CAPABILITY_OPTIONS_STORE = {}

    def self.enable_capability(name, on:) = ENABLED_CAPABILITIES[name] << on
    def self.set_capability_options(name, on:, **opts) = (CAPABILITY_OPTIONS_STORE[[name, on]] = opts)
    def self.capability_options(name, for_type:) = CAPABILITY_OPTIONS_STORE[[name, for_type]]
    def self.register_capability(name, mod) = (REGISTERED_CAPABILITIES[name] = mod)
    def self.reset! = (REGISTERED_CAPABILITIES.clear; ENABLED_CAPABILITIES.clear; CAPABILITY_OPTIONS_STORE.clear)

    def self.record!(**_kwargs)
      # Returns a minimal struct so callers get a non-nil new recording
      Struct.new(:id).new(SecureRandom.uuid)
    end
  end
end

require "test_helper"

module GemTemplate
  module Services
    class DuplicationServiceTest < Minitest::Test
      # -------------------------------------------------------------------
      # Minimal stub recording that responds to duplicate_in_place!
      # -------------------------------------------------------------------
      class StubRecording
        attr_reader :last_call_args

        def initialize(raise_error: nil, return_value: :new_recording)
          @raise_error  = raise_error
          @return_value = return_value
        end

        def duplicate_in_place!(**kwargs, &block)
          @last_call_args = kwargs
          block&.call(@return_value)
          raise @raise_error if @raise_error

          @return_value
        end
      end

      def setup
        @recording     = StubRecording.new(return_value: :the_new_recording)
        @actor         = :test_user
      end

      # -------------------------------------------------------------------
      # Success path
      # -------------------------------------------------------------------

      def test_success_returns_success_result
        result = DuplicationService.call(recording: @recording, actor: @actor)

        assert result.success?
        assert_equal :the_new_recording, result.value
      end

      def test_success_result_is_not_failure
        result = DuplicationService.call(recording: @recording, actor: @actor)

        refute result.failure?
      end

      def test_passes_actor_to_duplicate_in_place
        DuplicationService.call(recording: @recording, actor: @actor)

        assert_equal @actor, @recording.last_call_args[:actor]
      end

      def test_passes_prefix_to_duplicate_in_place
        DuplicationService.call(recording: @recording, actor: @actor, prefix: "[COPY] ")

        assert_equal "[COPY] ", @recording.last_call_args[:prefix]
      end

      def test_passes_suffix_to_duplicate_in_place
        DuplicationService.call(recording: @recording, actor: @actor, suffix: " — clone")

        assert_equal " — clone", @recording.last_call_args[:suffix]
      end

      def test_passes_include_children_to_duplicate_in_place
        DuplicationService.call(recording: @recording, actor: @actor, include_children: ["Section"])

        assert_equal ["Section"], @recording.last_call_args[:include_children]
      end

      def test_passes_exclude_children_to_duplicate_in_place
        DuplicationService.call(recording: @recording, actor: @actor, exclude_children: ["Tag"])

        assert_equal ["Tag"], @recording.last_call_args[:exclude_children]
      end

      def test_passes_impersonator_to_duplicate_in_place
        DuplicationService.call(recording: @recording, actor: @actor, impersonator: :admin)

        assert_equal :admin, @recording.last_call_args[:impersonator]
      end

      def test_passes_metadata_to_duplicate_in_place
        meta = { source: "api" }
        DuplicationService.call(recording: @recording, actor: @actor, metadata: meta)

        assert_equal meta, @recording.last_call_args[:metadata]
      end

      def test_defaults_prefix_to_default_sentinel
        DuplicationService.call(recording: @recording, actor: @actor)

        assert_equal :default, @recording.last_call_args[:prefix]
      end

      def test_defaults_suffix_to_default_sentinel
        DuplicationService.call(recording: @recording, actor: @actor)

        assert_equal :default, @recording.last_call_args[:suffix]
      end

      # -------------------------------------------------------------------
      # after_duplicate callback
      # -------------------------------------------------------------------

      def test_after_duplicate_proc_is_invoked
        received = nil
        callback = ->(new_rec) { received = new_rec }

        DuplicationService.call(recording: @recording, actor: @actor, after_duplicate: callback)

        assert_equal :the_new_recording, received
      end

      # -------------------------------------------------------------------
      # Block-style result handling
      # -------------------------------------------------------------------

      def test_block_receives_success_result
        yielded_result = nil

        DuplicationService.call(recording: @recording, actor: @actor) do |result|
          yielded_result = result
        end

        assert_predicate yielded_result, :success?
      end

      # -------------------------------------------------------------------
      # Failure — AccessDenied
      # -------------------------------------------------------------------

      def test_failure_on_access_denied
        recording = StubRecording.new(raise_error: RecordingStudio::AccessDenied.new("denied"))
        result = DuplicationService.call(recording: recording, actor: @actor)

        assert result.failure?
        assert_equal "denied", result.error
      end

      # -------------------------------------------------------------------
      # Failure — CapabilityDisabled
      # -------------------------------------------------------------------

      def test_failure_on_capability_disabled
        recording = StubRecording.new(raise_error: RecordingStudio::CapabilityDisabled.new("disabled"))
        result = DuplicationService.call(recording: recording, actor: @actor)

        assert result.failure?
        assert_equal "disabled", result.error
      end

      # -------------------------------------------------------------------
      # Failure — unexpected StandardError
      # -------------------------------------------------------------------

      def test_failure_on_standard_error
        recording = StubRecording.new(raise_error: StandardError.new("unexpected"))
        result = DuplicationService.call(recording: recording, actor: @actor)

        assert result.failure?
        assert_equal "unexpected", result.error
      end

      def test_failure_value_is_nil
        recording = StubRecording.new(raise_error: StandardError.new("boom"))
        result = DuplicationService.call(recording: recording, actor: @actor)

        assert_nil result.value
      end
    end
  end
end
