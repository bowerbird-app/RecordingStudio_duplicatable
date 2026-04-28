# frozen_string_literal: true

require "test_helper"

class GemTemplateTest < Minitest::Test
  def test_version_exists
    refute_nil ::GemTemplate::VERSION
  end

  def test_engine_exists
    assert_kind_of Class, ::GemTemplate::Engine
  end

  def test_dummy_app_uses_flatpack_sidebar_layout
    layout_path = File.expand_path("dummy/app/views/layouts/flat_pack_sidebar.html.erb", __dir__)
    assert File.exist?(layout_path)

    application_controller_path = File.expand_path("dummy/app/controllers/application_controller.rb", __dir__)
    controller_source = File.read(application_controller_path)
    assert_includes controller_source, "flat_pack_sidebar"
  end

  def test_recording_studio_capabilities_are_off_by_default
    initializer_path = File.expand_path("dummy/config/initializers/recording_studio.rb", __dir__)
    initializer_source = File.read(initializer_path)

    assert_includes initializer_source, "Built-in capabilities remain disabled"
    refute_includes initializer_source, "config.features."
  end

  def test_dummy_readme_explains_dummy_app_purpose
    readme_path = File.expand_path("dummy/README.md", __dir__)
    readme_source = File.read(readme_path)

    assert_includes readme_source, "This Rails app exists to validate the Recording Studio addon template"
    assert_includes readme_source, "/recording_studio"
    assert_includes readme_source, "/recording_studio_accessible"
  end

  def test_dummy_app_configures_accessible_engine_explicitly
    gemfile_path = File.expand_path("dummy/Gemfile", __dir__)
    gemfile_source = File.read(gemfile_path)
    assert_includes gemfile_source, %(gem "recording_studio_accessible")

    application_path = File.expand_path("dummy/config/application.rb", __dir__)
    application_source = File.read(application_path)
    assert_includes application_source, %(Gem.loaded_specs.key?("recording_studio_accessible"))

    routes_path = File.expand_path("dummy/config/routes.rb", __dir__)
    routes_source = File.read(routes_path)
    assert_includes routes_source, "mount RecordingStudioAccessible::Engine"

    workspace_path = File.expand_path("dummy/app/models/workspace.rb", __dir__)
    workspace_source = File.read(workspace_path)
    assert_includes workspace_source, "RecordingStudioAccessible::AllowsAccessibleChildren"
    assert_includes workspace_source, "recording_studio_accessible_children :access, :boundary"

    seeds_path = File.expand_path("dummy/db/seeds.rb", __dir__)
    seeds_source = File.read(seeds_path)
    assert_includes seeds_source, "RecordingStudioAccessible::Engine"
  end

  def test_dummy_home_page_mentions_template_workflow
    view_path = File.expand_path("dummy/app/views/home/index.html.erb", __dir__)
    view_source = File.read(view_path)

    assert_includes view_source, "Template workflow"
    assert_includes view_source, "Workspace state"
    assert_includes view_source, "Recording Studio mount"
  end

  def test_engine_home_page_uses_flatpack_components
    view_path = File.expand_path("../app/views/gem_template/home/index.html.erb", __dir__)
    view_source = File.read(view_path)

    assert_includes view_source, "FlatPack::PageTitle::Component"
    assert_includes view_source, "FlatPack::Card::Component"
    assert_includes view_source, "FlatPack::Button::Component"
    assert_includes view_source, "FlatPack::Badge::Component"
  end
end
