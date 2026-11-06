# frozen_string_literal: true

require_relative "../test_helper"

class AccessibleHomeScopingTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Rails.application.load_seed
    @admin = User.find_by!(email: "admin@admin.com")
    @page = Page.find_by!(slug: "launch-plan")
    @recording = RecordingStudio::Recording.find_by!(recordable: @page)
  end

  test "signed-in admin sees seeded recordables they can view" do
    sign_in @admin
    get "/"

    assert_response :success
    assert_includes response.body, "Launch Plan"
  end

  test "signed-in actor without grants does not see or open seeded recordables" do
    outsider = User.create!(
      email: "home-outsider-#{SecureRandom.hex(4)}@example.com",
      password: "Password",
      password_confirmation: "Password"
    )
    sign_in outsider

    get "/"
    assert_response :success
    refute_includes response.body, "Launch Plan"

    get page_path(@page.slug)
    assert_response :not_found
  end

  test "duplicate of an unseen recording looks missing instead of leaking access denial" do
    outsider = User.create!(
      email: "dup-outsider-#{SecureRandom.hex(4)}@example.com",
      password: "Password",
      password_confirmation: "Password"
    )
    sign_in outsider

    post "/recording_studio_duplicatable/recordings/#{@recording.id}/duplicate"

    assert_response :redirect
    assert_equal I18n.t("recording_studio.duplicatable.flashes.no_recording"), flash[:alert]
  end
end
