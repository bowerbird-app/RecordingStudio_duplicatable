# frozen_string_literal: true

require "test_helper"
require "action_controller"

ActionController::Base.singleton_class.class_eval do
  define_method(:allow_browser) { |**_options| } unless method_defined?(:allow_browser)
  define_method(:stale_when_importmap_changes) {} unless method_defined?(:stale_when_importmap_changes)
end

require_relative "dummy/app/controllers/application_controller"
require_relative "dummy/app/controllers/home_controller"

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
    Current.impersonator = nil if Current.respond_to?(:impersonator=)

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
    assert_includes readme_source, "gem-provided duplicate route"
    assert_includes readme_source, "included vs excluded child copying"
    refute_includes readme_source, "/pages/setup"
  end

  def test_dummy_home_page_mentions_pages_reports_and_folders_demo
    view_path = File.expand_path("dummy/app/views/home/index.html.erb", __dir__)
    view_source = File.read(view_path)

    assert_includes view_source, "Duplicatable Demo"
    assert_includes view_source, "FlatPack::SectionTitle::Component"
    assert_includes view_source, "duplicate_recording_path_for(page)"
    assert_includes view_source, "duplicate_recording_path_for(report)"
    assert_includes view_source, "duplicate_recording_path_for(folder)"
    assert_includes view_source, "built-in duplication endpoint"
    refute_includes view_source, "xl:grid-cols-2"
  end

  def test_dummy_recordable_card_links_to_show_view_and_stays_minimal
    view_path = File.expand_path("dummy/app/views/home/_recordable_card.html.erb", __dir__)
    view_source = File.read(view_path)

    assert_includes view_source, 'text: "Show"'
    assert_includes view_source, "text: \"\#{child_count} children\""
    assert_includes view_source, 'text: "Duplicate"'
    assert_includes view_source, "url: recordable_path"
    assert_includes view_source, "form_with url: duplicate_path"
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
    assert_includes(
      controller_source,
      'subtitle: "How to duplicate something with the built-in route, plus the custom option when you need it."'
    )
    assert_includes controller_source, "duplicate_recording_path"
    assert_includes controller_source, 'title: "Custom controller (optional)"'
    assert_includes controller_source, 'title: "What gets copied"'
    refute_includes controller_source, 'title: "2. Register the recordable type"'
    assert_includes view_source, "FlatPack::SectionTitle::Component"
    assert_includes view_source, "section[:title].present? || section[:subtitle].present?"
    assert_includes view_source, "anchor_link: true"
    assert_includes view_source, "FlatPack::Table::Component"
    assert_includes view_source, "FlatPack::CodeBlock::Component"
  end

  def test_dummy_home_controller_uses_page_report_folder_show_and_engine_duplicate_helper
    controller_path = File.expand_path("dummy/app/controllers/home_controller.rb", __dir__)
    controller_source = File.read(controller_path)

    assert_includes controller_source, "duplicate_recording_path_for"
    assert_includes controller_source, "recording_studio_duplicatable.duplicate_recording_path"
    assert_includes controller_source, "show_page"
    assert_includes controller_source, "show_report"
    assert_includes controller_source, "show_folder"
    assert_includes controller_source, "Report.find_by!(slug: params[:slug])"
    assert_includes controller_source, "Folder.find_by!(slug: params[:slug])"
    assert_includes controller_source, "@child_folder_recordings"
    assert_includes controller_source, "render :show_recordable"
    refute_includes controller_source, "duplicate_page"
    refute_includes controller_source, "duplicate_report"
    refute_includes controller_source, "duplicate_folder"
  end

  def test_dummy_home_controller_load_recordings_groups_recordables_by_class_name
    controller = HomeController.new
    recording_studio_defined = Object.const_defined?(:RecordingStudio)
    recording_studio_module =
      recording_studio_defined ? RecordingStudio : Object.const_set(:RecordingStudio, Module.new)
    recording_class_defined = recording_studio_module.const_defined?(:Recording, false)
    recording_class = fetch_or_define_recording_class(
      recording_studio_module,
      recording_class_defined
    )
    page_class = Class.new do
      def self.name = "Page"

      attr_reader :id

      def initialize(id)
        @id = id
      end
    end
    report_class = Class.new do
      def self.name = "Report"

      attr_reader :id

      def initialize(id)
        @id = id
      end
    end
    page = page_class.new(1)
    report = report_class.new(2)
    queried_conditions = []
    scope = Object.new

    scope.define_singleton_method(:includes) do |*_args|
      self
    end

    scope.define_singleton_method(:where) do |conditions|
      queried_conditions << conditions
      []
    end

    original_unscoped = recording_class.method(:unscoped) if recording_class.respond_to?(:unscoped)
    recording_class.singleton_class.send(:define_method, :unscoped) { scope }

    begin
      assert_equal({}, controller.send(:load_recordings_for, [page], [report]))
    ensure
      if original_unscoped
        recording_class.singleton_class.send(:define_method, :unscoped, original_unscoped)
      else
        recording_class.singleton_class.send(:remove_method, :unscoped)
      end

      recording_studio_module.send(:remove_const, :Recording) unless recording_class_defined
      Object.send(:remove_const, :RecordingStudio) unless recording_studio_defined
    end

    assert_equal(
      [
        { recordable_type: "Page", recordable_id: [1] },
        { recordable_type: "Report", recordable_id: [2] }
      ],
      queried_conditions
    )
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

  def test_dummy_routes_include_guides_show_pages_reports_folders_and_engine_mount
    routes_path = File.expand_path("dummy/config/routes.rb", __dir__)
    routes_source = File.read(routes_path)

    assert_includes routes_source, 'mount RecordingStudioDuplicatable::Engine, at: "/recording_studio_duplicatable"'
    assert_includes routes_source, 'get "guides/:slug"'
    assert_includes routes_source, 'get "pages/:slug"'
    assert_includes routes_source, 'get "reports/:slug"'
    assert_includes routes_source, 'get "folders/:slug"'
    refute_includes routes_source, 'post "pages/:slug/duplicate"'
    refute_includes routes_source, 'post "reports/:slug/duplicate"'
    refute_includes routes_source, 'post "folders/:slug/duplicate"'
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
    assert_includes view_source, "@child_folder_recordings.any?"
    assert_includes view_source, 'title: "Child folders"'
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

  def test_readme_documents_builtin_duplication_endpoint_and_lower_level_apis
    readme_path = File.expand_path("../README.md", __dir__)
    readme_source = File.read(readme_path)

    assert_includes readme_source, "duplicate_recording_path(recording_id: recording.id)"
    assert_includes readme_source, "config.actor = -> { Current.actor }"
    assert_includes readme_source, "DuplicationService.call"
    assert_includes readme_source, "duplicate_in_place!"
    assert_includes readme_source, "host app `ApplicationController`"
  end

  def test_engine_route_and_application_controller_files_define_builtin_duplication_endpoint
    routes_path = File.expand_path("../config/routes.rb", __dir__)
    routes_source = File.read(routes_path)
    application_controller_path = File.expand_path(
      "../app/controllers/recording_studio_duplicatable/application_controller.rb",
      __dir__
    )
    application_controller_source = File.read(application_controller_path)
    duplications_controller_path = File.expand_path(
      "../app/controllers/recording_studio_duplicatable/duplications_controller.rb",
      __dir__
    )
    duplications_controller_source = File.read(duplications_controller_path)

    assert_includes routes_source, 'post "recordings/:recording_id/duplicate"'
    assert_includes application_controller_source, "defined?(::ApplicationController) ? ::ApplicationController : ActionController::Base"
    assert_includes application_controller_source, "current_duplication_actor"
    assert_includes duplications_controller_source, "Services::DuplicationService.call"
    assert_includes duplications_controller_source, "current_duplication_impersonator"
    assert_includes duplications_controller_source, "redirect_back"
  end

  private

  def fetch_or_define_recording_class(recording_studio_module, recording_class_defined)
    if recording_class_defined
      recording_studio_module.const_get(:Recording, false)
    else
      recording_studio_module.const_set(:Recording, Class.new)
    end
  end
end
