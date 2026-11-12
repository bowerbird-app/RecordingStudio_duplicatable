# frozen_string_literal: true

require "test_helper"

class DuplicatableApiTest < Minitest::Test
  def test_registration_is_a_noop_without_recording_studio_api
    refute Object.const_defined?(:RecordingStudioApi, false)

    assert_nil RecordingStudio::Duplicatable::Api.register_capability_action!
  end

  def test_engine_registers_duplicate_action_before_recording_studio_api_after_initialize
    initializer = RecordingStudioDuplicatable::Engine.initializers.find do |item|
      item.name == "recording_studio_duplicatable.register_recording_studio_api_action"
    end

    refute_nil initializer
    assert_equal "recording_studio_api.after_initialize", initializer.before
  end
end
