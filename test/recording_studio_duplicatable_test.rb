# frozen_string_literal: true

require "test_helper"

class RecordingStudioDuplicatableTest < Minitest::Test
  def setup
    @current_defined = Object.const_defined?(:Current)
    @original_current = Current if @current_defined
  end

  def teardown
    if @current_defined
      Object.send(:remove_const, :Current) if Object.const_defined?(:Current)
      Object.const_set(:Current, @original_current)
    elsif Object.const_defined?(:Current)
      Object.send(:remove_const, :Current)
    end
  end

  def test_version_exists
    refute_nil ::RecordingStudioDuplicatable::VERSION
  end

  def test_engine_exists
    assert_kind_of Class, ::RecordingStudioDuplicatable::Engine
  end

  def test_ensure_current_impersonator_attribute_adds_optional_accessor
    Object.send(:remove_const, :Current) if Object.const_defined?(:Current)
    Object.const_set(:Current, Class.new(ActiveSupport::CurrentAttributes) do
      attribute :actor
    end)

    refute Current.respond_to?(:impersonator)

    RecordingStudioDuplicatable.ensure_current_impersonator_attribute!

    assert Current.respond_to?(:impersonator)
    assert Current.respond_to?(:impersonator=)
    assert_nil Current.impersonator
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
    assert_includes initializer_source, 'config.recordable_types = ["Workspace", "Page"]'
    refute_includes initializer_source, "config.features."
  end

  def test_dummy_readme_describes_page_demo
    readme_path = File.expand_path("dummy/README.md", __dir__)
    readme_source = File.read(readme_path)

    assert_includes readme_source, "Page"
    assert_includes readme_source, "/pages/setup"
    assert_includes readme_source, "simple page-card duplication demo"
    refute_includes readme_source, "/up"
  end

  def test_dummy_home_page_mentions_page_demo
    view_path = File.expand_path("dummy/app/views/home/index.html.erb", __dir__)
    view_source = File.read(view_path)

    assert_includes view_source, "Duplicatable Demo"
    assert_includes view_source, "This is a demo of the duplication functionality"
    assert_includes view_source, "Page"
    assert_includes view_source, "Duplicate"
    assert_includes view_source, "style: :danger"
    refute_includes view_source, "Health check"
    refute_includes view_source, "Recording Studio mount"
    refute_includes view_source, "style: :error"
  end

  def test_dummy_show_page_mentions_api_docs_card
    view_path = File.expand_path("dummy/app/views/home/show.html.erb", __dir__)
    view_source = File.read(view_path)

    assert_includes view_source, "Duplicatable API"
    assert_includes view_source, "Example"
    assert_includes view_source, "FlatPack::Card::Component"
  end

  def test_dummy_home_controller_uses_page_duplication_service
    controller_path = File.expand_path("dummy/app/controllers/home_controller.rb", __dir__)
    controller_source = File.read(controller_path)

    assert_includes controller_source, "RecordingStudioDuplicatable::Services::DuplicationService.call"
    assert_includes controller_source, "duplicate_page"
    assert_includes controller_source, "Page.find_by!(slug: params[:slug])"
  end

  def test_dummy_page_model_enables_duplicatable_capability
    model_path = File.expand_path("dummy/app/models/page.rb", __dir__)
    model_source = File.read(model_path)

    assert_includes model_source, "RecordingStudioDuplicatable::Capabilities::Duplicatable.with"
    assert_includes model_source, "belongs_to :workspace"
    assert_includes model_source, "before_validation :ensure_slug"
  end

  def test_dummy_routes_include_page_docs_and_duplication
    routes_path = File.expand_path("dummy/config/routes.rb", __dir__)
    routes_source = File.read(routes_path)

    assert_includes routes_source, 'get "pages/:slug"'
    assert_includes routes_source, 'post "pages/:slug/duplicate"'
    refute_includes routes_source, 'post "duplicate_workspace"'
  end

  def test_dummy_sidebar_uses_duplicatable_navigation
    sidebar_path = File.expand_path("dummy/app/views/layouts/flat_pack/_sidebar.html.erb", __dir__)
    sidebar_source = File.read(sidebar_path)

    assert_includes sidebar_source, 'title: "Duplicatable"'
    assert_includes sidebar_source, 'label: "Setup"'
    assert_includes sidebar_source, 'label: "Use"'
    assert_includes sidebar_source, 'label: "Methods"'
    refute_includes sidebar_source, 'label: "Health"'
    refute_includes sidebar_source, 'label: "Recording Studio"'
  end

  def test_dummy_top_nav_removes_old_title_text
    top_nav_path = File.expand_path("dummy/app/views/layouts/flat_pack/_top_nav.html.erb", __dir__)
    top_nav_source = File.read(top_nav_path)

    refute_includes top_nav_source, "Recording Studio Duplicatable"
  end

  def test_dummy_top_nav_uses_center_slot_to_push_avatar_right
    top_nav_path = File.expand_path("dummy/app/views/layouts/flat_pack/_top_nav.html.erb", __dir__)
    top_nav_source = File.read(top_nav_path)

    assert_includes top_nav_source, "<% nav.center do %>"
    assert_operator top_nav_source.index("<% nav.center do %>"), :<,
                    top_nav_source.index("<% nav.right do %>")
  end

  def test_engine_home_page_uses_flatpack_components
    view_path = File.expand_path("../app/views/recording_studio_duplicatable/home/index.html.erb", __dir__)
    view_source = File.read(view_path)

    assert_includes view_source, "RecordingStudio Duplicatable"
    assert_includes view_source, "FlatPack::PageTitle::Component"
    assert_includes view_source, "FlatPack::Card::Component"
    assert_includes view_source, "FlatPack::Button::Component"
    assert_includes view_source, "FlatPack::Badge::Component"
  end
end
