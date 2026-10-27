# frozen_string_literal: true

require_relative "../test_helper"

class DuplicatableHostLocaleOverrideTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  HOST_NO_RECORDING = "HOST No recording is available to duplicate."
  HOST_HOME_TITLE = "HOST RecordingStudio Duplicatable"
  OVERRIDE_KEY = "recording_studio.duplicatable.flashes.no_recording"
  HOME_TITLE_KEY = "recording_studio.duplicatable.home.title"
  BOOT_HOST_LOCALE = Rails.root.join("config/locales/recording_studio_duplicatable_host.en.yml")
  FRESH_HOST_LOCALE = Rails.root.join("test/locales/duplicatable_host_override.en.yml")

  setup do
    @load_path_before = I18n.load_path.dup
    @backend_before = I18n.backend
    Rails.application.load_seed
    @user = User.find_by!(email: "admin@admin.com")
  end

  teardown do
    I18n.backend = @backend_before if @backend_before
    assert_equal @load_path_before, I18n.load_path,
                 "test must not leave I18n.load_path modified"
  end

  # Real-boot-order guard: host file under config/locales must win without any
  # test-time load_path mutation. Render assertion uses the missing-recording flash.
  test "host locale override for recording_studio.duplicatable wins on boot order" do
    assert File.exist?(BOOT_HOST_LOCALE)
    assert_includes File.read(BOOT_HOST_LOCALE), HOST_NO_RECORDING
    assert_equal HOST_NO_RECORDING, I18n.t(OVERRIDE_KEY)
    assert_equal @load_path_before, I18n.load_path,
                 "boot-order test must not mutate I18n.load_path"

    sign_in @user
    post "/recording_studio_duplicatable/recordings/00000000-0000-0000-0000-000000000000/duplicate"

    assert_response :redirect
    assert_equal HOST_NO_RECORDING, flash[:alert]
    follow_redirect!
    assert_response :success
    assert_includes response.body, HOST_NO_RECORDING
  end

  # Test-only fixture applied via backend.load_translations(file) on top of the
  # already-initialized backend — never mutates I18n.load_path (Marshal).
  test "fresh-backend last-file-wins host fixture overrides dummy english on engine status" do
    assert File.exist?(FRESH_HOST_LOCALE), "expected test-only host override fixture at #{FRESH_HOST_LOCALE}"
    assert_includes File.read(FRESH_HOST_LOCALE), HOST_HOME_TITLE

    sign_in @user

    snapshot = i18n_backend_translations_snapshot
    I18n.t(HOME_TITLE_KEY)
    I18n.backend.load_translations(FRESH_HOST_LOCALE.to_s)

    assert_equal @load_path_before, I18n.load_path
    assert_equal HOST_HOME_TITLE, I18n.t(HOME_TITLE_KEY)
    assert_equal HOST_NO_RECORDING, I18n.t(OVERRIDE_KEY)

    get "/engine_status"
    assert_response :success
    assert_includes response.body, HOST_HOME_TITLE
    refute_includes response.body, "HOST FlatPack"
  ensure
    restore_i18n_backend_translations(snapshot) if snapshot
  end

  private

  def i18n_backend_translations_snapshot
    backend = I18n.backend
    backend.send(:init_translations) unless backend.initialized?
    translations =
      if backend.respond_to?(:translations)
        backend.translations
      else
        backend.instance_variable_get(:@translations)
      end
    return unless translations

    deep_plain_copy(translations)
  end

  def restore_i18n_backend_translations(snapshot)
    backend = I18n.backend
    backend.instance_variable_set(:@translations, snapshot)
    backend.instance_variable_set(:@initialized, true) if backend.instance_variable_defined?(:@initialized)
  end

  def deep_plain_copy(value)
    case value
    when Hash
      value.each_with_object({}) { |(key, nested), copy| copy[key] = deep_plain_copy(nested) }
    when Array
      value.map { |nested| deep_plain_copy(nested) }
    else
      value
    end
  end
end
