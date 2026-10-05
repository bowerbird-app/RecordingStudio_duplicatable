# frozen_string_literal: true

require_relative "../test_helper"

class AccessibleGrantsTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_seed
    @admin = User.find_by!(email: "admin@admin.com")
    @workspace = Workspace.find_by!(name: "Documentation Workspace")
    @root_recording = RecordingStudio::Recording.unscoped.find_by!(recordable: @workspace, parent_recording_id: nil)
  end

  test "seeded grants store string roles and go through Accessible services" do
    grants = RecordingStudioAccessible.access_recordings_for(@root_recording).map(&:recordable)

    assert(grants.any?)
    assert(grants.all? { |access| access.role.is_a?(String) })
    assert_equal "admin", RecordingStudioAccessible.role_for(actor: @admin, recording: @root_recording).to_s
  end

  test "grant_access upserts a string role without writing Access rows directly" do
    extra = User.create!(
      email: "extra-#{SecureRandom.hex(4)}@admin.com",
      password: "Password",
      password_confirmation: "Password"
    )

    result = RecordingStudioAccessible.grant_access(
      recording: @root_recording,
      actor: extra,
      role: :edit,
      manager_actor: @admin
    )

    assert result.success?, result.error.to_s
    access = result.value.recordable
    assert_equal "edit", access.role
    assert RecordingStudioAccessible.authorized?(actor: extra, recording: @root_recording, role: :edit)
  end
end
