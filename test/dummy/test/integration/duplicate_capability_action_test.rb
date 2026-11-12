# frozen_string_literal: true

require_relative "../test_helper"

unless defined?(RecordingStudioApi)
  module RecordingStudioApi
    class AuthorizationError < StandardError; end
    class NotFoundError < StandardError; end
    class UnsupportedActionError < StandardError; end
  end
end

class DuplicateCapabilityActionTest < ActiveSupport::TestCase
  ActionContext = Struct.new(
    :recording,
    :api_client,
    :credential,
    :access_grant,
    :params,
    keyword_init: true
  )
  ApiPrincipal = Struct.new(:id)

  class AccessibleRecordings
    def initialize(root_recording)
      @root_recording = root_recording
    end

    def find_by(id:)
      RecordingStudio::Recording.where(root_recording_id: @root_recording.id).find_by(id: id)
    end
  end

  class AccessGrant
    attr_reader :actor, :root_recording, :authorize_calls

    def initialize(actor:, root_recording:)
      @actor = actor
      @root_recording = root_recording
      @authorize_calls = []
    end

    def accessible_recordings
      AccessibleRecordings.new(@root_recording)
    end

    def authorize!(recording:, role:)
      @authorize_calls << [recording, role]
      return if RecordingStudioAccessible.authorized?(actor: @actor, recording: recording, role: role)

      raise RecordingStudioApi::AuthorizationError, "API access is not authorized to duplicate this recording."
    end
  end

  setup do
    Rails.application.load_seed
    @admin = User.find_by!(email: "admin@admin.com")
    @workspace = Workspace.find_by!(name: "Documentation Workspace")
    @root_recording = RecordingStudio::Recording.unscoped.find_by!(recordable: @workspace, parent_recording_id: nil)
    @page = Page.find_by!(slug: "launch-plan")
    @recording = RecordingStudio::Recording.find_by!(recordable: @page)
    Current.actor = @admin
  end

  test "authorized edit grant duplicates the recording in place" do
    access_grant = AccessGrant.new(actor: @admin, root_recording: @root_recording)
    before_count = RecordingStudio::Recording.where(root_recording_id: @root_recording.id).count

    duplicate = RecordingStudio::Duplicatable::Api::DuplicateRecording.call(
      action_context(recording: @recording, access_grant: access_grant)
    )

    assert_equal [[@recording, :edit]], access_grant.authorize_calls
    assert_equal @root_recording.id, duplicate.root_recording_id
    assert_equal @recording.parent_recording_id, duplicate.parent_recording_id
    assert_equal "Launch Plan (Copy)", duplicate.recordable.title
    assert_equal before_count + 1 + @page.comments.count,
                 RecordingStudio::Recording.where(root_recording_id: @root_recording.id).count
  end

  test "view grant is forbidden and does not duplicate" do
    viewer = User.create!(
      email: "api-viewer-#{SecureRandom.hex(4)}@example.com",
      password: "Password",
      password_confirmation: "Password"
    )
    result = RecordingStudioAccessible.grant_access(
      recording: @root_recording,
      actor: viewer,
      role: :view,
      manager_actor: @admin
    )
    assert result.success?, result.error.to_s

    access_grant = AccessGrant.new(actor: viewer, root_recording: @root_recording)
    before_ids = RecordingStudio::Recording.where(root_recording_id: @root_recording.id).pluck(:id)

    error = assert_raises(RecordingStudioApi::AuthorizationError) do
      RecordingStudio::Duplicatable::Api::DuplicateRecording.call(
        action_context(recording: @recording, access_grant: access_grant)
      )
    end

    assert_equal "API access is not authorized to duplicate this recording.", error.message
    assert_equal [[@recording, :edit]], access_grant.authorize_calls
    assert_equal before_ids.sort, RecordingStudio::Recording.where(root_recording_id: @root_recording.id).pluck(:id).sort
  end

  test "cross-workspace recording is not found in the grant root" do
    other_workspace = Workspace.create!(name: "Other Workspace #{SecureRandom.hex(4)}")
    other_root = RecordingStudio::Recording.unscoped.create!(
      recordable: other_workspace,
      parent_recording_id: nil
    )
    other_page = other_workspace.pages.create!(
      title: "Foreign Page",
      slug: "foreign-page-#{SecureRandom.hex(4)}",
      summary: "Lives in another workspace.",
      body: "Must stay out of the first grant."
    )
    foreign_recording = RecordingStudio::Recording.unscoped.create!(
      recordable: other_page,
      root_recording_id: other_root.id,
      parent_recording_id: other_root.id
    )

    access_grant = AccessGrant.new(actor: @admin, root_recording: @root_recording)
    before_foreign = RecordingStudio::Recording.where(root_recording_id: other_root.id).count

    error = assert_raises(RecordingStudioApi::NotFoundError) do
      RecordingStudio::Duplicatable::Api::DuplicateRecording.call(
        action_context(recording: foreign_recording, access_grant: access_grant)
      )
    end

    assert_equal "Recording was not found in this API scope", error.message
    assert_empty access_grant.authorize_calls
    assert_equal before_foreign, RecordingStudio::Recording.where(root_recording_id: other_root.id).count
  end

  private

  def action_context(recording:, access_grant:)
    ActionContext.new(
      recording: recording,
      api_client: ApiPrincipal.new("client-1"),
      credential: ApiPrincipal.new("credential-1"),
      access_grant: access_grant,
      params: {}
    )
  end
end
