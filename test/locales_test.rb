# frozen_string_literal: true

require "test_helper"
require "yaml"
require "i18n"

class LocalesTest < Minitest::Test
  # rubocop:disable Style/FormatStringToken, Layout/LineLength -- I18n tokens / locale literals match en.yml
  EXPECTED_LEAVES = {
    "recording_studio.duplicatable.home.title" => "RecordingStudio Duplicatable",
    "recording_studio.duplicatable.home.subtitle" =>
      "The engine is mounted and ready to provide in-place duplication for Recording Studio recordables.",
    "recording_studio.duplicatable.home.badges.engine_mounted" => "Engine mounted",
    "recording_studio.duplicatable.home.badges.flatpack_enabled" => "FlatPack enabled",
    "recording_studio.duplicatable.home.badges.recursive_duplication" => "Recursive duplication",
    "recording_studio.duplicatable.home.whats_working.title" => "What's working",
    "recording_studio.duplicatable.home.whats_working.subtitle" => "Core addon capabilities already wired in.",
    "recording_studio.duplicatable.home.whats_working.routes" => "Rails engine routes are mounted and responding.",
    "recording_studio.duplicatable.home.whats_working.no_tables" =>
      "The behavior-only engine does not add host application tables.",
    "recording_studio.duplicatable.home.whats_working.flatpack" =>
      "FlatPack now drives the dummy app styling directly, including the Rounded theme.",
    "recording_studio.duplicatable.home.whats_working.dummy" =>
      "The dummy app exercises authentication, FlatPack layouts, Recording Studio setup, and live duplication.",
    "recording_studio.duplicatable.home.how_to_use.title" => "How to use it",
    "recording_studio.duplicatable.home.how_to_use.subtitle" =>
      "The standard path for enabling duplication in a host app.",
    "recording_studio.duplicatable.home.how_to_use.install_accessible" =>
      "Install <code>recording_studio_accessible</code>, run its install + migration generators, and apply its migrations before using duplication.",
    "recording_studio.duplicatable.home.how_to_use.add_gem" =>
      "Add the gem to the host app and run <code>rails generate recording_studio_duplicatable:install</code> if you want the initializer and mount.",
    "recording_studio.duplicatable.home.how_to_use.opt_in" =>
      "Opt the desired recordable types in with <code>include RecordingStudio::Capabilities::Duplicatable.to(**opts)</code>.",
    "recording_studio.duplicatable.home.how_to_use.configure" =>
      "Configure Recording Studio recordable types and capability options in the host app initializer.",
    "recording_studio.duplicatable.home.how_to_use.validate" =>
      "Use the dummy app to validate recursive duplication, asset scanning, and authentication flows.",
    "recording_studio.duplicatable.home.flatpack.title" => "FlatPack usage",
    "recording_studio.duplicatable.home.flatpack.subtitle" =>
      "This page itself now uses FlatPack components for its primary UI structure.",
    "recording_studio.duplicatable.home.flatpack.body" =>
      "Use FlatPack cards, buttons, badges, inputs, and layout primitives as the default path for addon UI. Keep raw HTML for simple semantic content only.",
    "recording_studio.duplicatable.home.flatpack.docs_button" => "View FlatPack documentation",
    "recording_studio.duplicatable.home.install_flow.title" => "Install flow",
    "recording_studio.duplicatable.home.install_flow.subtitle" => "What the host app generator path covers.",
    "recording_studio.duplicatable.home.install_flow.bundle" =>
      "Add the gem to your host app and run <code>bundle install</code>.",
    "recording_studio.duplicatable.home.install_flow.accessible_generators" =>
      "Run <code>rails generate recording_studio_accessible:install</code>, then <code>rails generate recording_studio_accessible:migrations</code>, then <code>bin/rails db:migrate</code>.",
    "recording_studio.duplicatable.home.install_flow.duplicatable_install" =>
      "Run <code>rails generate recording_studio_duplicatable:install</code> to mount the engine and add configuration.",
    "recording_studio.duplicatable.home.install_flow.no_migrations" =>
      "No RecordingStudio Duplicatable migrations are required; use the install generator for mount and configuration only.",
    "recording_studio.duplicatable.home.install_flow.styles" =>
      "Verify your host app styles do not override the FlatPack tokens you want to keep.",
    "recording_studio.duplicatable.flashes.no_actor" =>
      "No current actor is available to duplicate this recording.",
    "recording_studio.duplicatable.flashes.no_recording" => "No recording is available to duplicate.",
    "recording_studio.duplicatable.flashes.created" => "Created duplicate \"%{label}\".",
    "recording_studio.duplicatable.flashes.failed" => "Duplication failed: %{error}",
    "recording_studio.duplicatable.errors.access_denied" =>
      "Actor does not have :edit access for duplication"
  }.freeze
  # rubocop:enable Style/FormatStringToken, Layout/LineLength

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

    assert_equal "RecordingStudio Duplicatable", duplicatable.fetch("home").fetch("title")
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
