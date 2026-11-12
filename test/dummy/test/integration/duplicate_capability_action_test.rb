# frozen_string_literal: true

require_relative "../test_helper"

class DuplicateCapabilityActionTest < ActionDispatch::IntegrationTest
  setup do
    skip "recording_studio_api is not available" unless defined?(RecordingStudioApi)

    Rails.application.load_seed
    host! "example.com"

    @admin = User.find_by!(email: "admin@admin.com")
    @workspace = Workspace.find_by!(name: "Documentation Workspace")
    @root_recording = RecordingStudio::Recording.unscoped.find_by!(recordable: @workspace, parent_recording_id: nil)
    @page = Page.find_by!(slug: "launch-plan")
    @recording = RecordingStudio::Recording.find_by!(recordable: @page)
    Current.actor = @admin
    @edit_token = issue_token(access_point: @root_recording, role: :edit, name: "Edit duplicate")
    @view_token = issue_token(access_point: @root_recording, role: :view, name: "View duplicate")
  end

  test "authorized edit grant duplicates the recording in place" do
    before_count = RecordingStudio::Recording.where(root_recording_id: @root_recording.id).count

    post "/recording_studio_api/api/v1/pages/#{@recording.id}/actions/duplicate",
         headers: bearer(@edit_token),
         as: :json

    assert_response :success, response.body
    body = json_body
    assert_equal @root_recording.id, body.fetch("root_id")
    assert_equal @recording.parent_recording_id, body.fetch("parent_id")
    duplicate = RecordingStudio::Recording.find(body.fetch("id"))
    assert_equal "Launch Plan (Copy)", duplicate.recordable.title
    assert_equal before_count + 1 + @page.comments.count,
                 RecordingStudio::Recording.where(root_recording_id: @root_recording.id).count
  end

  test "view grant is forbidden and does not duplicate" do
    before_ids = RecordingStudio::Recording.where(root_recording_id: @root_recording.id).pluck(:id)

    post "/recording_studio_api/api/v1/pages/#{@recording.id}/actions/duplicate",
         headers: bearer(@view_token),
         as: :json

    assert_response :forbidden, response.body
    assert_equal before_ids.sort, RecordingStudio::Recording.where(root_recording_id: @root_recording.id).pluck(:id).sort
  end

  test "cross-workspace recording is not found in the grant root" do
    other_user = User.create!(
      email: "other-#{SecureRandom.hex(4)}@example.com",
      password: "Password",
      password_confirmation: "Password"
    )
    other_workspace = Workspace.create!(name: "Other Workspace #{SecureRandom.hex(4)}")
    other_root = RecordingStudio::Recording.unscoped.find_or_create_by!(
      recordable: other_workspace,
      parent_recording_id: nil
    )
    Current.actor = other_user
    bootstrap = RecordingStudioAccessible.bootstrap_owner_access!(recording: other_root, actor: other_user)
    raise bootstrap.error if bootstrap.failure?

    other_page = other_workspace.pages.create!(
      title: "Foreign Page",
      slug: "foreign-page-#{SecureRandom.hex(4)}",
      summary: "Lives in another workspace.",
      body: "Must stay out of the first grant."
    )
    foreign_recording = RecordingStudio::Recording.unscoped.find_or_create_by!(
      recordable: other_page,
      root_recording_id: other_root.id,
      parent_recording_id: other_root.id
    )
    before_foreign = RecordingStudio::Recording.where(root_recording_id: other_root.id).count
    Current.actor = @admin

    post "/recording_studio_api/api/v1/pages/#{foreign_recording.id}/actions/duplicate",
         headers: bearer(@edit_token),
         as: :json

    assert_response :not_found, response.body
    assert_equal before_foreign, RecordingStudio::Recording.where(root_recording_id: other_root.id).count
  end

  test "duplicating a recording with Access children leaves the Access count unchanged" do
    extra = User.create!(
      email: "access-child-#{SecureRandom.hex(4)}@example.com",
      password: "Password",
      password_confirmation: "Password"
    )
    grant = RecordingStudioAccessible.grant_access(
      recording: @recording,
      actor: extra,
      role: :view,
      manager_actor: @admin
    )
    assert grant.success?, grant.error.to_s
    assert RecordingStudio::Recording.exists?(
      recordable_type: "RecordingStudio::Access",
      parent_recording_id: @recording.id
    )

    access_count_before = RecordingStudio::Recording.where(recordable_type: "RecordingStudio::Access").count

    post "/recording_studio_api/api/v1/pages/#{@recording.id}/actions/duplicate",
         headers: bearer(@edit_token),
         as: :json

    assert_response :success, response.body
    assert_equal access_count_before, RecordingStudio::Recording.where(recordable_type: "RecordingStudio::Access").count
  end

  private

  def json_body
    JSON.parse(response.body)
  end

  def bearer(token)
    { "Authorization" => "Bearer #{token}" }
  end

  def issue_token(access_point:, role:, name:)
    RecordingStudioAccessible::AccessCreationContext.allow do
      provision = RecordingStudioApi::Services::ProvisionApiClient.call(
        access_point_recording: access_point,
        manager_actor: @admin,
        role: role,
        name: "#{name}-#{SecureRandom.hex(4)}"
      )
      raise provision.error unless provision.success?

      payload = provision.value
      token_result = RecordingStudioApi::Services::IssueOauthAccessToken.call(
        grant_type: "client_credentials",
        client_id: payload.fetch(:credential).oauth_client_id,
        client_secret: payload.fetch(:token)
      )
      raise token_result.error unless token_result.success?

      token_result.value.fetch(:access_token)
    end
  end
end
