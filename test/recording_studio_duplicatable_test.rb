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

  def test_duplicatable_capability_requires_recording_studio_capability_support
    capability_path = File.expand_path("../lib/recording_studio_duplicatable/capabilities/duplicatable.rb", __dir__)
    capability_source = File.read(capability_path)

    assert_includes capability_source, 'require "recording_studio/capability"'
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

    layout_source = File.read(layout_path)
    assert_includes layout_source, 'data-theme="rounded"'
    assert_includes layout_source, 'stylesheet_link_tag "tailwind"'

    application_controller_path = File.expand_path("dummy/app/controllers/application_controller.rb", __dir__)
    controller_source = File.read(application_controller_path)
    assert_includes controller_source, "flat_pack_sidebar"
  end

  def test_dummy_app_stylesheets_link_flatpack_assets_and_remove_custom_theme_overrides
    application_css_path = File.expand_path("dummy/app/assets/stylesheets/application.css", __dir__)
    application_css_source = File.read(application_css_path)
    application_layout_path = File.expand_path("dummy/app/views/layouts/application.html.erb", __dir__)
    application_layout_source = File.read(application_layout_path)
    sidebar_layout_path = File.expand_path("dummy/app/views/layouts/flat_pack_sidebar.html.erb", __dir__)
    sidebar_layout_source = File.read(sidebar_layout_path)
    tailwind_css_path = File.expand_path("dummy/app/assets/tailwind/application.css", __dir__)
    tailwind_css_source = File.read(tailwind_css_path)
    dummy_gemfile_path = File.expand_path("dummy/Gemfile", __dir__)
    dummy_gemfile_source = File.read(dummy_gemfile_path)

    assert_includes application_layout_source, 'stylesheet_link_tag "flat_pack/variables"'
    assert_includes application_layout_source, 'stylesheet_link_tag "flat_pack/rich_text"'
    assert_includes application_layout_source, 'stylesheet_link_tag "flat_pack/application"'
    assert_includes sidebar_layout_source, 'stylesheet_link_tag "flat_pack/variables"'
    assert_includes sidebar_layout_source, 'stylesheet_link_tag "flat_pack/rich_text"'
    assert_includes sidebar_layout_source, 'stylesheet_link_tag "flat_pack/application"'
    assert_includes dummy_gemfile_source, 'gem "tailwindcss-rails"'
    assert_includes tailwind_css_source, '@import "tailwindcss" source(none);'
    assert_includes tailwind_css_source, '@source "../../views/**/*.erb";'
    assert_includes \
      tailwind_css_source,
      '@source "../../../../../../usr/local/bundle/**/bundler/gems/flatpack-*/app/components/**/*.rb";'
    assert_includes \
      tailwind_css_source,
      '@source "../../../../../../home/*/.local/share/mise/installs/ruby/*/lib/ruby/gems/*/bundler/gems/flatpack-*/app/components/**/*.rb";'
    refute_includes application_css_source, "flat_pack/"
    refute_includes tailwind_css_source, "@theme {"
    refute_includes tailwind_css_source, "--color-fp-primary"
    refute_includes tailwind_css_source, ":root {"
  end

  def test_recording_studio_capabilities_are_off_by_default
    initializer_path = File.expand_path("dummy/config/initializers/recording_studio.rb", __dir__)
    initializer_source = File.read(initializer_path)

    assert_includes initializer_source, "Built-in capabilities remain disabled"
    assert_includes initializer_source, "config.impersonator = -> { Current.impersonator }"
    assert_includes initializer_source, "config.require_recordable_declarations = true"
    refute_includes initializer_source, "config.include_children"
    assert_match(
      /config\.recordable_types = \[\s*"Workspace", "Page", "Report", "Folder", "Comment"\s*\]/,
      initializer_source
    )
    refute_includes initializer_source, "config.features."
  end

  def test_dummy_readme_describes_recordable_demo
    readme_path = File.expand_path("dummy/README.md", __dir__)
    readme_source = File.read(readme_path)

    assert_includes readme_source, "Page`, `Report`, `Folder`, and `Comment`"
    assert_includes readme_source, "/guides/setup"
    assert_includes readme_source, "/guides/approach"
    assert_includes readme_source, "gem-provided duplicate route"
    assert_includes readme_source, "included vs excluded child copying"
    assert_includes readme_source, "recording_studio_accessible"
    assert_includes readme_source, "RecordingStudioAccessible.authorized?"
    assert_includes readme_source, "install Recording Studio Accessible"
    refute_includes readme_source, "RecordingStudio::Services::AccessCheck"
    refute_includes readme_source, "/pages/setup"
  end

  def test_dummy_home_page_mentions_pages_reports_and_folders_demo
    view_path = File.expand_path("dummy/app/views/home/index.html.erb", __dir__)
    view_source = File.read(view_path)

    assert_includes view_source, "Duplicatable Demo"
    assert_includes view_source, "FlatPack::SectionTitle::Component"
    assert_includes view_source, "style: :danger"
    assert_includes view_source, "duplicate_recording_path_for(page)"
    assert_includes view_source, "duplicate_recording_path_for(report)"
    assert_includes view_source, "duplicate_recording_path_for(folder)"
    assert_includes view_source, "built-in duplication endpoint"
    refute_includes view_source, 'class="grid gap-4 md:grid-cols-2 xl:grid-cols-3"'
    refute_includes view_source, "style: :error"
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
    assert_includes controller_source, '"approach"'
    assert_includes controller_source, '"methods"'
    assert_includes controller_source, 'anchor: "accessible-install"'
    assert_includes controller_source, 'anchor: "mount-and-actor-setup"'
    assert_includes controller_source, 'anchor: "capability"'
    assert_includes controller_source, 'title: "Install Recording Studio Accessible first"'
    assert_includes controller_source, 'title: "Setup route and controller"'
    assert_includes controller_source, 'title: "Built-in route and controller"'
    assert_includes controller_source, 'title: "Add capability to recordable"'
    assert_includes controller_source, "recording_studio_accessible:migrations"
    assert_includes controller_source, "bin/rails db:migrate"
    assert_includes controller_source, "config.require_recordable_declarations = true"
    assert_includes controller_source, "config.impersonator = -> { Current.impersonator }"
    assert_includes controller_source, "recording_studio_recordable label: \"Page\""
    assert_includes controller_source, "RecordingStudio.enable_capability(:accessible, on: self)"
    assert_includes controller_source, 'title: "Approach"'
    assert_includes controller_source, 'title: "General approach"'
    assert_includes(
      controller_source,
      "subtitle: \"The gem keeps duplication deliberately narrow: duplicate the " \
      "recording and recordable in place, and configure " \
      "child-copy rules where the capability is declared.\""
    )
    assert_includes(
      controller_source,
      'subtitle: "Use the built-in flow when you want a simple in-place ' \
      'duplicate and predictable child-copy behavior."'
    )
    assert_includes(
      controller_source,
      "Duplicate is deliberately simple. Move or copy workflows belong in other " \
      "Recording Studio addon gems."
    )
    assert_includes(
      controller_source,
      "After duplication the default behavior is to refresh the current page. " \
      "A prefix or suffix can be added to distinguish the new recording."
    )
    assert_includes(
      controller_source,
      "Duplication copies the recordable and creates a new recording for that duplicate."
    )
    assert_includes(
      controller_source,
      "Control of what child items are included in duplication lives in this gem " \
      "through the capability options."
    )
    assert_includes controller_source, 'title: "Built-in route"'
    assert_includes(
      controller_source,
      'subtitle: "Post to the mounted engine when you want a simple duplicate ' \
      'button or link; duplication authorization is handled by RecordingStudioAccessible.authorized?."'
    )
    assert_includes controller_source, 'anchor: "custom-route-and-controller"'
    assert_includes controller_source, 'title: "Custom route and controller"'
    assert_includes controller_source, 'title: "Host app route and controller"'
    assert_includes controller_source, 'title: "Simple button"'
    assert_includes(
      controller_source,
      "The built-in controller redirects back after duplication, so the current page reloads by default."
    )
    assert_includes(
      controller_source,
      'subtitle: "Add your own POST route and controller action when you want ' \
      'to control the path, redirect, or response."'
    )
    assert_includes(
      controller_source,
      'post "/pages/:slug/duplicate", to: "pages#duplicate", as: :duplicate_page'
    )
    assert_includes controller_source, "class PagesController < ApplicationController"
    assert_includes controller_source, "page = Page.find_by!(slug: params[:slug])"
    assert_includes(
      controller_source,
      "recording = RecordingStudio::Recording.find_by!(recordable: page)"
    )
    assert_includes controller_source, "RecordingStudioDuplicatable::Services::DuplicationService.call"
    assert_includes(
      controller_source,
      "redirect_to page_path(duplicate_recording.recordable.slug), notice: " \
      '"Page duplicated"'
    )
    assert_includes controller_source, "redirect_to page_path(page.slug), alert: error"
    assert_includes controller_source, 'title: "Options"'
    assert_operator(
      controller_source.index("use"),
      :<,
      controller_source.index('title: "Built-in route"')
    )
    assert_operator(
      controller_source.index('"approach"'),
      :<,
      controller_source.index('"use"')
    )
    assert_operator(
      controller_source.rindex('"methods"'),
      :>,
      controller_source.index('title: "Built-in route"')
    )
    assert_includes(
      controller_source,
      'subtitle: "How to duplicate something with the built-in route or your own host-app route and controller."'
    )
    assert_includes(
      controller_source,
      "subtitle: \"Install Recording Studio Accessible first, apply its " \
      "migrations, then mount the engine, keep your current actor available, " \
      "and let duplication authorize through RecordingStudioAccessible.authorized?.\""
    )
    assert_includes(
      controller_source,
      "subtitle: \"Mount the engine to use the gem-provided duplication route " \
      "and controller with your existing Recording Studio actor resolver.\""
    )
    assert_includes(
      controller_source,
      "subtitle: \"Duplication depends on " \
      "RecordingStudioAccessible.authorized?, so install and migrate " \
      "Recording Studio Accessible before you use duplication.\""
    )
    assert_includes controller_source, "duplicate_recording_path"
    refute_includes controller_source, "RecordingStudio::Services::AccessCheck"
    refute_includes controller_source, 'title: "Host app link"'
    refute_includes controller_source, 'title: "What gets copied"'
    refute_includes controller_source, 'title: "Custom controller (optional)"'
    refute_includes controller_source, 'title: "Direct recording call"'
    refute_includes controller_source, 'title: "2. Register the recordable type"'
    assert_includes view_source, "FlatPack::SectionTitle::Component"
    assert_includes view_source, "section[:anchor].present?"
    assert_includes(
      view_source,
      "section[:title].present? || section[:subtitle].present?"
    )
    assert_includes view_source, "anchor_link: true"
    assert_includes view_source, "FlatPack::Table::Component"
    assert_includes view_source, "section[:list].present?"
    assert_includes view_source, "section[:list][:ordered]"
    assert_includes view_source, '<ol style="margin: 0; padding-left: 1.25rem;">'
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
    workspace_model_path = File.expand_path("dummy/app/models/workspace.rb", __dir__)
    workspace_model_source = File.read(workspace_model_path)
    page_model_path = File.expand_path("dummy/app/models/page.rb", __dir__)
    page_model_source = File.read(page_model_path)
    report_model_path = File.expand_path("dummy/app/models/report.rb", __dir__)
    report_model_source = File.read(report_model_path)
    folder_model_path = File.expand_path("dummy/app/models/folder.rb", __dir__)
    folder_model_source = File.read(folder_model_path)
    comment_model_path = File.expand_path("dummy/app/models/comment.rb", __dir__)
    comment_model_source = File.read(comment_model_path)

    assert_includes workspace_model_source, 'recording_studio_recordable label: "Workspace", root: true'
    assert_includes page_model_source, 'recording_studio_recordable label: "Page", root: false'
    assert_includes report_model_source, 'recording_studio_recordable label: "Report", root: false'
    assert_includes folder_model_source, 'recording_studio_recordable label: "Folder", root: false'
    assert_includes comment_model_source, 'recording_studio_recordable label: "Comment", root: false'
    assert_includes comment_model_source, 'allowed_parent_types: [ "Page", "Report", "Folder" ]'
    [workspace_model_source, page_model_source, report_model_source, folder_model_source].each do |source|
      assert_includes source, "RecordingStudio.enable_capability(:accessible, on: self)"
    end
    refute_includes comment_model_source, "RecordingStudio.enable_capability(:accessible"
    assert_match(/include_children: \[\s*"Comment"\s*\]/, page_model_source)
    assert_match(/exclude_children: \[\s*"Comment"\s*\]/, report_model_source)
    assert_match(/include_children: \[\s*"Folder", "Comment"\s*\]/, folder_model_source)
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
    assert_includes sidebar_source, 'href: guide_path("approach")'
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
    assert_includes seeds_source, "RecordingStudioAccessible.grant_access"
    refute_includes seeds_source, "RecordingStudio::Access.find_or_create_by!"
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
    refute_includes view_source, "tailwindcss:build"
  end

  def test_readme_documents_builtin_duplication_endpoint_and_lower_level_apis
    readme_path = File.expand_path("../README.md", __dir__)
    readme_source = File.read(readme_path)

    assert_includes readme_source, "recording_studio_accessible:install"
    assert_includes readme_source, "recording_studio_accessible:migrations"
    assert_includes readme_source, "RecordingStudioAccessible.authorized?"
    assert_includes readme_source, 'tag: "v4.0.0"'
    assert_includes readme_source, 'tag: "v0.6.0"'
    assert_includes readme_source, "recording_studio_recordable"
    assert_includes readme_source, "RecordingStudioAccessible.grant_access"
    assert_includes readme_source, "access_actor_types"
    assert_includes readme_source, "bin/rails db:migrate"
    assert_includes readme_source, "duplicate_recording_path(recording_id: recording.id)"
    assert_includes readme_source, "config.actor = -> { Current.actor }"
    assert_includes readme_source, "DuplicationService.call"
    assert_includes readme_source, "duplicate_in_place!"
    assert_includes readme_source, "host app `ApplicationController`"
    refute_includes readme_source, "RecordingStudio::Services::AccessCheck"
    refute_includes readme_source, "AccessCheck.allowed?"
  end

  def test_update_summary_documents_recording_studio_accessible_authorization_api
    update_summary_path = File.expand_path("../UPDATE_SUMMARY.md", __dir__)
    update_summary_source = File.read(update_summary_path)

    assert_includes update_summary_source, "RecordingStudioAccessible.authorized?"
    refute_includes update_summary_source, "RecordingStudio::Services::AccessCheck"
  end

  def test_gemspec_declares_recording_studio_accessible_runtime_dependency
    gemspec_path = File.expand_path("../recording_studio_duplicatable.gemspec", __dir__)
    gemspec_source = File.read(gemspec_path)

    assert_includes gemspec_source, 'spec.add_dependency "recording_studio", "~> 4.0"'
    assert_includes gemspec_source, 'spec.add_dependency "recording_studio_accessible", "~> 0.6"'
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
