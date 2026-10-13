# frozen_string_literal: true

require_relative "../test_helper"

# Render-level literal-English asserts for wave 2 copy. English output must
# match main. Does not rewrite other tests to expect HOST strings.
class Wave2I18nRenderTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Rails.application.load_seed
    @user = User.find_by!(email: "admin@admin.com")
  end

  test "engine home renders literal english from gem locale keys" do
    sign_in @user
    get "/recording_studio_duplicatable"

    assert_response :success
    assert_includes response.body, "RecordingStudio Duplicatable"
    assert_includes response.body,
                    "The engine is mounted and ready to provide in-place duplication for Recording Studio recordables."
    assert_includes response.body, "Engine mounted"
    assert_includes response.body, "FlatPack enabled"
    assert_includes response.body, "Recursive duplication"
    assert(
      response.body.include?("What's working") || response.body.include?("What&#39;s working"),
      "expected What's working heading in response body"
    )
    assert_includes response.body, "How to use it"
    assert_includes response.body, "View FlatPack documentation"
    assert_includes response.body, "Install flow"
    refute_includes response.body, "HOST RecordingStudio Duplicatable"
  end

  test "successful duplication flash renders literal english created message" do
    sign_in @user
    page = Page.find_by!(slug: "launch-plan")
    recording = RecordingStudio::Recording.unscoped.find_by!(recordable: page)

    post "/recording_studio_duplicatable/recordings/#{recording.id}/duplicate"

    assert_response :redirect
    assert_match(/\ACreated duplicate ".+"\.\z/, flash[:notice].to_s)
    assert_includes flash[:notice], "Created duplicate \""
    assert_includes flash[:notice], " (Copy)"
  end

  test "access denied flash maps known english through locale keys" do
    outsider = User.create!(
      email: "outsider-#{SecureRandom.hex(4)}@example.com",
      password: "Password",
      password_confirmation: "Password"
    )
    sign_in outsider
    page = Page.find_by!(slug: "feature-brief")
    recording = RecordingStudio::Recording.unscoped.find_by!(recordable: page)
    english = "Actor does not have :edit access for duplication"

    post "/recording_studio_duplicatable/recordings/#{recording.id}/duplicate"

    assert_response :redirect
    assert_equal "Duplication failed: #{english}", flash[:alert]
  end

  test "access denied flash translates in french and hosts can override english" do
    outsider = User.create!(
      email: "fr-outsider-#{SecureRandom.hex(4)}@example.com",
      password: "Password",
      password_confirmation: "Password"
    )
    page = Page.find_by!(slug: "feature-brief")
    recording = RecordingStudio::Recording.unscoped.find_by!(recordable: page)

    with_restored_i18n_backend do
      previous_locales = I18n.available_locales
      I18n.available_locales = (previous_locales + [:fr]).uniq
      I18n.backend.store_translations(:fr, {
        recording_studio: {
          duplicatable: {
            flashes: { failed: "Échec de la duplication : %{error}" },
            errors: { access_denied: "L'acteur n'a pas l'accès :edit pour dupliquer" }
          }
        }
      })
      I18n.backend.store_translations(:en, {
        recording_studio: {
          duplicatable: {
            errors: { access_denied: "HOST Actor does not have :edit access for duplication" }
          }
        }
      })

      sign_in outsider
      I18n.with_locale(:fr) do
        post "/recording_studio_duplicatable/recordings/#{recording.id}/duplicate"
        assert_response :redirect
        assert_equal "Échec de la duplication : L'acteur n'a pas l'accès :edit pour dupliquer", flash[:alert]
      end

      I18n.with_locale(:en) do
        post "/recording_studio_duplicatable/recordings/#{recording.id}/duplicate"
        assert_response :redirect
        assert_equal (
          "Duplication failed: HOST Actor does not have :edit access for duplication"
        ), flash[:alert]
      end
    ensure
      I18n.available_locales = previous_locales if defined?(previous_locales) && previous_locales
    end
  end

  private

  def with_restored_i18n_backend
    previous_load_path = I18n.load_path.dup
    previous_translations = i18n_backend_translations_snapshot
    yield
  ensure
    I18n.load_path.replace(previous_load_path)
    restore_i18n_backend_translations(previous_translations) if previous_translations
  end

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
