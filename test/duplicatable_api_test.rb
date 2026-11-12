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

  def test_api_handler_requires_edit_and_calls_duplicate_in_place
    source = File.read(
      File.expand_path("../lib/recording_studio/duplicatable/api.rb", __dir__)
    )
    handler = File.read(
      File.expand_path("../lib/recording_studio/duplicatable/api/duplicate_recording.rb", __dir__)
    )

    assert_includes source, "register_capability_action(:duplicate"
    assert_includes source, "capability: :duplicatable"
    assert_includes source, "required_role: :edit"
    assert_includes source, 'summary: "Duplicates this recording in place under the same parent."'
    refute_includes source, "register_mcp"
    refute_includes handler, "register_mcp"
    assert_includes handler, "context.access_grant.authorize!(recording: recording, role: :edit)"
    assert_includes handler, "context.access_grant.accessible_recordings.find_by(id: recording_id)"
    assert_includes handler, "recording.duplicate_in_place!"
  end
end
