# frozen_string_literal: true

require "test_helper"
require "yaml"
require "i18n"

class LocalesTest < Minitest::Test
  # rubocop:disable Style/FormatStringToken -- I18n tokens match en.yml
  EXPECTED_LEAVES = {
    "recording_studio.duplicatable.flashes.no_actor" =>
      "No current actor is available to duplicate this recording.",
    "recording_studio.duplicatable.flashes.no_recording" => "No recording is available to duplicate.",
    "recording_studio.duplicatable.flashes.created" => "Created duplicate \"%{label}\".",
    "recording_studio.duplicatable.flashes.failed" => "Duplication failed: %{error}",
    "recording_studio.duplicatable.errors.access_denied" =>
      "Actor does not have :edit access for duplication"
  }.freeze
  # rubocop:enable Style/FormatStringToken

  def setup
    seed_gem_english_translations!
  end

  def test_engine_ships_only_english_locale_files
    files = Dir[File.join(engine_locales_dir, "*")].map { |path| File.basename(path) }

    assert_equal ["en.yml"], files.sort
  end

  def test_engine_exposes_english_locale_path
    locale_path = File.expand_path(File.join(engine_locales_dir, "en.yml"))
    existent = RecordingStudioDuplicatable::Engine.paths["config/locales"].existent.map do |path|
      File.expand_path(path)
    end

    assert_includes existent, locale_path
  end

  def test_lib_ruby_files_do_not_mention_i18n_load_path
    lib_root = File.expand_path("../lib", __dir__)
    ruby_files = Dir[File.join(lib_root, "**", "*.rb")]

    assert_operator ruby_files.size, :>, 0

    ruby_files.each do |path|
      source = File.read(path)
      refute_includes source, "i18n.load_path", "#{path} must not mention i18n.load_path"
      refute_includes source, "I18n.load_path", "#{path} must not mention I18n.load_path"
    end
  end

  def test_engine_does_not_reappend_locales_to_i18n_load_path
    engine_source = File.read(File.expand_path("../lib/recording_studio_duplicatable/engine.rb", __dir__))

    refute_includes engine_source, "I18n.load_path"
    refute_includes engine_source, "i18n.load_path"
    refute_includes engine_source, "app.config.i18n.load_path"
  end

  def test_english_keys_resolve_without_missing_translations
    I18n.with_locale(:en) do
      EXPECTED_LEAVES.each do |full_key, english|
        translation = I18n.t(full_key, default: nil)

        assert_equal english, translation, "#{full_key} should resolve to #{english.inspect}"
        assert_equal english, I18n.t(full_key, raise: true)
      end

      assert_equal(
        'Created duplicate "Page (Copy)".',
        I18n.t("recording_studio.duplicatable.flashes.created", label: "Page (Copy)")
      )
      assert_equal(
        "Duplication failed: Actor does not have :edit access for duplication",
        I18n.t(
          "recording_studio.duplicatable.flashes.failed",
          error: "Actor does not have :edit access for duplication"
        )
      )
    end
  end

  def test_en_yml_nests_keys_under_recording_studio_duplicatable
    tree = locale_tree(File.join(engine_locales_dir, "en.yml"), "en")
    duplicatable = tree.fetch("recording_studio").fetch("duplicatable")

    refute duplicatable.key?("home")
    assert_equal "No recording is available to duplicate.", duplicatable.fetch("flashes").fetch("no_recording")
    assert_equal(
      "Actor does not have :edit access for duplication",
      duplicatable.fetch("errors").fetch("access_denied")
    )
  end

  def test_yaml_boolean_looking_keys_are_quoted_when_present
    raw = File.read(File.join(engine_locales_dir, "en.yml"))
    boolean_looking = raw.scan(/^\s*((?:yes|no|on|off|true|false|null)):/i).flatten

    boolean_looking.each do |key|
      assert_match(/["']#{Regexp.escape(key)}["']:/, raw,
                   "YAML key #{key.inspect} must be quoted so Psych does not coerce it")
    end
  end

  def test_gemspec_does_not_depend_on_internationalization
    gemspec = File.read(File.expand_path("../recording_studio_duplicatable.gemspec", __dir__))

    refute_includes gemspec, "recording_studio_internationalization"
  end

  def test_dummy_gemfile_does_not_depend_on_internationalization
    gemfile = File.read(File.expand_path("dummy/Gemfile", __dir__))

    refute_includes gemfile, "recording_studio_internationalization"
  end

  def test_every_locale_key_has_a_call_site
    source_roots = [
      File.expand_path("../app", __dir__),
      File.expand_path("../lib", __dir__)
    ]
    sources = source_roots.flat_map { |root| Dir[File.join(root, "**", "*.{rb,erb}")] }.map { |path| File.read(path) }
    joined = sources.join("\n")

    EXPECTED_LEAVES.each_key do |full_key|
      short = full_key.delete_prefix("recording_studio.duplicatable.")
      assert(
        joined.include?(full_key) || joined.include?(short) || joined.include?(%("#{short}")) ||
          joined.include?(%('#{short}')),
        "locale key #{full_key} has no call site in app/ or lib/"
      )
    end
  end

  private

  def seed_gem_english_translations!
    tree = locale_tree(File.join(engine_locales_dir, "en.yml"), "en")
    I18n.backend.store_translations(:en, tree)
  end

  def engine_locales_dir
    File.expand_path("../config/locales", __dir__)
  end

  def locale_tree(path, root_key)
    parsed = YAML.safe_load_file(path)
    parsed.fetch(root_key)
  end
end
