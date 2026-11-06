# frozen_string_literal: true

require_relative "../test_helper"

class AuthorizeWriteTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_seed
    @admin = User.find_by!(email: "admin@admin.com")
    @workspace = Workspace.find_by!(name: "Documentation Workspace")
    @root_recording = RecordingStudio::Recording.unscoped.find_by!(recordable: @workspace, parent_recording_id: nil)
  end

  test "dummy authorize_write is configured and is not actor presence" do
    initializer = File.read(Rails.root.join("config/initializers/recording_studio.rb"))

    assert_includes initializer, "config.authorize_write"
    assert_includes initializer, "RecordingStudioAccessible.authorized?"
    assert_includes initializer, "AccessCreationContext.allowed?"
    refute_includes initializer, "recordable.actor == actor"
    refute_match(/authorize_write\s*=\s*->\(actor:, \*\*\) \{ actor\.present\? \}/, initializer)
    refute_includes initializer, "allow_unauthorized_writes = true"
  end

  test "dummy authorize_write allows the seeded owner and denies missing or ungranted actors" do
    authorizer = RecordingStudio.configuration.authorize_write
    folder = Folder.new(name: "Write policy folder")

    refute_nil authorizer
    refute authorizer.call(actor: nil, root_recording: @root_recording, recordable: folder)
    refute authorizer.call(
      actor: User.new(email: "ghost@example.com"),
      root_recording: @root_recording,
      recordable: folder
    )

    outsider = User.create!(
      email: "write-outsider-#{SecureRandom.hex(4)}@example.com",
      password: "Password",
      password_confirmation: "Password"
    )

    refute authorizer.call(actor: outsider, root_recording: @root_recording, recordable: folder)
    assert authorizer.call(actor: @admin, root_recording: @root_recording, recordable: folder)
  end

  test "dummy authorize_write allows Access rows through AccessCreationContext not self-grant" do
    authorizer = RecordingStudio.configuration.authorize_write
    outsider = User.create!(
      email: "access-outsider-#{SecureRandom.hex(4)}@example.com",
      password: "Password",
      password_confirmation: "Password"
    )
    access = RecordingStudio::Access.new(actor: outsider, role: :view)

    refute authorizer.call(actor: outsider, root_recording: @root_recording, recordable: access)
    assert RecordingStudioAccessible::AccessCreationContext.allow {
      authorizer.call(actor: outsider, root_recording: @root_recording, recordable: access)
    }
    assert authorizer.call(actor: @admin, root_recording: @root_recording, recordable: access)
  end
end
