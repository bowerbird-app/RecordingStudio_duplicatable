# frozen_string_literal: true

require "test_helper"
require "action_controller"
require "action_controller/test_case"
require_relative "../app/controllers/recording_studio_duplicatable/application_controller"
require_relative "../app/controllers/recording_studio_duplicatable/duplications_controller"

module RecordingStudioDuplicatable
  class DuplicationsControllerTest < ActionController::TestCase
    tests DuplicationsController

    def setup
      @routes = ActionDispatch::Routing::RouteSet.new
      @routes.draw do
        post "/recordings/:recording_id/duplicate",
             to: "recording_studio_duplicatable/duplications#create",
             as: :duplicate_recording
        root to: "recording_studio_duplicatable/home#index"
      end
      @original_allow_forgery_protection = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = false
      setup_current_class
      setup_recording_studio
    end

    def teardown
      ActionController::Base.allow_forgery_protection = @original_allow_forgery_protection
      restore_current_class
      restore_recording_studio
    end

    def test_engine_route_exposes_duplicate_recording_path
      assert_equal(
        "/recordings/rec-1/duplicate",
        @routes.url_helpers.duplicate_recording_path(recording_id: "rec-1")
      )
    end

    def test_create_uses_recording_studio_actor_and_impersonator_resolvers
      @recording_studio_configuration.actor = -> { :configured_actor }
      @recording_studio_configuration.impersonator = -> { :configured_impersonator }
      Current.actor = :fallback_actor
      Current.impersonator = :fallback_admin
      recording = build_recording(id: "rec-1", title: "Page (Copy)")
      install_recording_scope(recording)
      captured_args = nil

      RecordingStudioDuplicatable::Services::DuplicationService.stub(
        :call,
        lambda do |**kwargs|
          captured_args = kwargs
          success_result(recording)
        end
      ) do
        @request.env["HTTP_REFERER"] = "/pages/example"
        post :create, params: { recording_id: "rec-1" }
      end

      assert_redirected_to "/pages/example"
      assert_equal :configured_actor, captured_args[:actor]
      assert_equal :configured_impersonator, captured_args[:impersonator]
      assert_equal %(Created duplicate "Page (Copy)".), flash[:notice]
    end

    def test_create_falls_back_to_current_impersonator
      @recording_studio_configuration.actor = -> { :configured_actor }
      @recording_studio_configuration.impersonator = -> {}
      Current.impersonator = :admin
      recording = build_recording(id: "rec-impersonator", title: "Page (Copy)")
      install_recording_scope(recording)
      captured_impersonator = nil

      RecordingStudioDuplicatable::Services::DuplicationService.stub(
        :call,
        lambda do |**kwargs|
          captured_impersonator = kwargs[:impersonator]
          success_result(recording)
        end
      ) do
        post :create, params: { recording_id: "rec-impersonator" }
      end

      assert_redirected_to "/"
      assert_equal :admin, captured_impersonator
    end

    def test_create_falls_back_to_current_actor
      @recording_studio_configuration.actor = -> {}
      Current.actor = :current_actor
      recording = build_recording(id: "rec-2", title: "Report (Copy)")
      install_recording_scope(recording)
      captured_actor = nil

      RecordingStudioDuplicatable::Services::DuplicationService.stub(
        :call,
        lambda do |**kwargs|
          captured_actor = kwargs[:actor]
          success_result(recording)
        end
      ) do
        post :create, params: { recording_id: "rec-2" }
      end

      assert_redirected_to "/"
      assert_equal :current_actor, captured_actor
    end

    def test_create_redirects_with_alert_when_actor_is_missing
      @recording_studio_configuration.actor = -> {}
      Current.actor = nil
      called = false

      RecordingStudioDuplicatable::Services::DuplicationService.stub(
        :call,
        lambda do |**_kwargs|
          called = true
          success_result(nil)
        end
      ) do
        post :create, params: { recording_id: "rec-3" }
      end

      refute called
      assert_redirected_to "/"
      assert_equal "No current actor is available to duplicate this recording.", flash[:alert]
    end

    def test_create_redirects_with_alert_when_recording_is_missing
      Current.actor = :current_actor
      install_recording_scope(nil)
      called = false

      RecordingStudioDuplicatable::Services::DuplicationService.stub(
        :call,
        lambda do |**_kwargs|
          called = true
          success_result(nil)
        end
      ) do
        post :create, params: { recording_id: "missing" }
      end

      refute called
      assert_redirected_to "/"
      assert_equal "No recording is available to duplicate.", flash[:alert]
    end

    def test_create_redirects_with_failure_message_when_duplication_is_denied
      Current.actor = :current_actor
      recording = build_recording(id: "rec-4", title: "Folder (Copy)")
      install_recording_scope(recording)

      RecordingStudioDuplicatable::Services::DuplicationService.stub(
        :call,
        ->(**_kwargs) { failure_result("Actor does not have :edit access for duplication") }
      ) do
        post :create, params: { recording_id: "rec-4" }
      end

      assert_redirected_to "/"
      assert_equal "Duplication failed: Actor does not have :edit access for duplication", flash[:alert]
    end

    private

    def build_recording(id:, title:)
      recordable = Struct.new(:title).new(title)
      Struct.new(:id, :recordable).new(id, recordable)
    end

    def install_recording_scope(recording)
      scope = Object.new
      scope.define_singleton_method(:find_by) do |id:|
        id == recording&.id ? recording : nil
      end

      @recording_class.define_singleton_method(:unscoped) { scope }
    end

    def success_result(recording)
      build_result(success: true, value: recording, error: nil)
    end

    def failure_result(error)
      build_result(success: false, value: nil, error: error)
    end

    def build_result(success:, value:, error:)
      Object.new.tap do |result|
        result.define_singleton_method(:success?) { success }
        result.define_singleton_method(:value) { value }
        result.define_singleton_method(:error) { error }
      end
    end

    def setup_current_class
      @current_defined = Object.const_defined?(:Current)
      @original_current = Current if @current_defined
      Object.send(:remove_const, :Current) if Object.const_defined?(:Current)
      Object.const_set(:Current, Class.new(ActiveSupport::CurrentAttributes) do
        attribute :actor, :impersonator
      end)
    end

    def restore_current_class
      Object.send(:remove_const, :Current) if Object.const_defined?(:Current)
      Object.const_set(:Current, @original_current) if @current_defined
    end

    def setup_recording_studio
      @recording_studio_defined = Object.const_defined?(:RecordingStudio)
      @original_recording_studio = RecordingStudio if @recording_studio_defined
      @recording_studio_configuration = Struct.new(:actor, :impersonator).new(-> {}, -> {})
      @recording_class = Class.new

      recording_studio = Module.new
      recording_studio.const_set(:Recording, @recording_class)
      recording_studio.instance_variable_set(:@configuration, @recording_studio_configuration)
      recording_studio.define_singleton_method(:configuration) { @configuration }

      Object.send(:remove_const, :RecordingStudio) if Object.const_defined?(:RecordingStudio)
      Object.const_set(:RecordingStudio, recording_studio)
    end

    def restore_recording_studio
      Object.send(:remove_const, :RecordingStudio) if Object.const_defined?(:RecordingStudio)
      Object.const_set(:RecordingStudio, @original_recording_studio) if @recording_studio_defined
    end
  end
end
