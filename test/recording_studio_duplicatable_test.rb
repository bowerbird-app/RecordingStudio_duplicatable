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
    assert_includes initializer_source, 'config.recordable_types = ["Workspace", "Page", "Report", "Folder", "Comment"]'
    refute_includes initializer_source, "config.features."
  end

  def test_dummy_readme_describes_recordable_demo
    readme_path = File.expand_path("dummy/README.md", __dir__)
    readme_source = File.read(readme_path)

    assert_includes readme_source, "Page`, `Report`, `Folder`, and `Comment`"
    assert_includes readme_source, "/guides/setup"
    assert_includes readme_source, "included vs excluded child copying"
    refute_includes readme_source, "/pages/setup"
  end

  def test_dummy_home_page_mentions_pages_reports_and_folders_demo
    view_path = File.expand_path("dummy/app/views/home/index.html.erb", __dir__)
    view_source = File.read(view_path)

    assert_includes view_source, "Duplicatable Demo"
    assert_includes view_source, "FlatPack::SectionTitle::Component"
    assert_includes view_source, "page_path(page.slug)"
    assert_includes view_source, "report_path(report.slug)"
    assert_includes view_source, "folder_path(folder.slug)"
    assert_includes view_source, "duplicate_report_path"
    assert_includes view_source, "duplicate_folder_path"
    refute_includes view_source, "xl:grid-cols-2"
  end

  def test_dummy_recordable_card_links_to_show_view_and_stays_minimal
    view_path = File.expand_path("dummy/app/views/home/_recordable_card.html.erb", __dir__)
    view_source = File.read(view_path)

    assert_includes view_source, 'text: "Show"'
    assert_includes view_source, 'text: "#{child_count} children"'
    assert_includes view_source, 'text: "Duplicate"'
    assert_includes view_source, "url: recordable_path"
    refute_includes view_source, "card.header"
    refute_includes view_source, "recordable.body.truncate"
  end

  def test_static_guides_use_flatpack_sections_tables_and_code_blocks
    controller_path = File.expand_path("dummy/app/controllers/guides_controller.rb", __dir__)
    controller_source = File.read(controller_path)
    view_path = File.expand_path("dummy/app/views/guides/show.html.erb", __dir__)
    view_source = File.read(view_path)

    assert_includes controller_source, "GUIDE_CONTENT"
    assert_includes controller_source, '"setup"'
    assert_includes controller_source, '"methods"'
    refute_includes controller_source, 'title: "2. Register the recordable type"'
    assert_includes view_source, "FlatPack::SectionTitle::Component"
    assert_includes view_source, "anchor_link: true"
    assert_includes view_source, "FlatPack::Table::Component"
    assert_includes view_source, "FlatPack::CodeBlock::Component"
  end

  def test_dummy_home_controller_uses_page_report_folder_show_and_duplication_service
    controller_path = File.expand_path("dummy/app/controllers/home_controller.rb", __dir__)
    controller_source = File.read(controller_path)

    assert_includes controller_source, "RecordingStudioDuplicatable::Services::DuplicationService.call"
    assert_includes controller_source, "show_page"
    assert_includes controller_source, "show_report"
    assert_includes controller_source, "show_folder"
    assert_includes controller_source, "duplicate_page"
    assert_includes controller_source, "duplicate_report"
    assert_includes controller_source, "duplicate_folder"
    assert_includes controller_source, "Report.find_by!(slug: params[:slug])"
    assert_includes controller_source, "Folder.find_by!(slug: params[:slug])"
    assert_includes controller_source, "render :show_recordable"
  end

  def test_dummy_page_report_and_folder_models_configure_child_duplication_rules
    page_model_path = File.expand_path("dummy/app/models/page.rb", __dir__)
    page_model_source = File.read(page_model_path)
    report_model_path = File.expand_path("dummy/app/models/report.rb", __dir__)
    report_model_source = File.read(report_model_path)
    folder_model_path = File.expand_path("dummy/app/models/folder.rb", __dir__)
    folder_model_source = File.read(folder_model_path)
    comment_model_path = File.expand_path("dummy/app/models/comment.rb", __dir__)
    comment_model_source = File.read(comment_model_path)

    assert_includes page_model_source, 'include_children: ["Comment"]'
    assert_includes report_model_source, 'exclude_children: ["Comment"]'
    assert_includes folder_model_source, 'include_children: ["Folder", "Comment"]'
    assert_includes page_model_source, "has_many :comments, as: :commentable"
    assert_includes report_model_source, "has_many :comments, as: :commentable"
    assert_includes folder_model_source, "belongs_to :parent_folder, class_name: \"Folder\", optional: true"
    assert_includes folder_model_source, "has_many :child_folders"
    assert_includes comment_model_source, "belongs_to :commentable, polymorphic: true"
  end

  def test_dummy_routes_include_guides_show_pages_reports_folders_and_duplication
    routes_path = File.expand_path("dummy/config/routes.rb", __dir__)
    routes_source = File.read(routes_path)

    assert_includes routes_source, 'get "guides/:slug"'
    assert_includes routes_source, 'get "pages/:slug"'
    assert_includes routes_source, 'get "reports/:slug"'
    assert_includes routes_source, 'get "folders/:slug"'
    assert_includes routes_source, 'post "pages/:slug/duplicate"'
    assert_includes routes_source, 'post "reports/:slug/duplicate"'
    assert_includes routes_source, 'post "folders/:slug/duplicate"'
  end

  def test_dummy_sidebar_uses_static_guide_navigation
    sidebar_path = File.expand_path("dummy/app/views/layouts/flat_pack/_sidebar.html.erb", __dir__)
    sidebar_source = File.read(sidebar_path)

    assert_includes sidebar_source, 'href: guide_path("setup")'
    assert_includes sidebar_source, 'href: guide_path("use")'
    assert_includes sidebar_source, 'href: guide_path("methods")'
    refute_includes sidebar_source, "page_path("
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

  def test_dummy_seeds_create_pages_reports_folders_and_comment_recordings
    seeds_path = File.expand_path("dummy/db/seeds.rb", __dir__)
    seeds_source = File.read(seeds_path)

    assert_includes seeds_source, "DEMO_PAGES"
    assert_includes seeds_source, "DEMO_REPORTS"
    assert_includes seeds_source, "DEMO_FOLDERS"
    assert_includes seeds_source, "ensure_comment_recordings!"
    assert_includes seeds_source, "ensure_folder_recordings!"
    assert_includes seeds_source, "parent_folder: folder"
    assert_includes seeds_source, "parent_recording_id: parent_recording.id"
  end

  def test_dummy_recordable_show_view_lists_children
    view_path = File.expand_path("dummy/app/views/home/show_recordable.html.erb", __dir__)
    view_source = File.read(view_path)

    assert_includes view_source, "recordable_title(@recordable)"
    assert_includes view_source, "text: \"\#{@child_recordings.size} children\""
    assert_includes view_source, "FlatPack::Badge::Component"
    assert_includes view_source, "FlatPack::SectionTitle::Component"
    assert_includes view_source, "FlatPack::Table::Component"
    assert_includes view_source, "child_recording.recordable_type"
    assert_includes view_source, "child_recording_title(child_recording)"
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
