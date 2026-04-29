# frozen_string_literal: true

require "recording_studio_duplicatable/version"
require "recording_studio_duplicatable/engine"
require "recording_studio_duplicatable/configuration"
require "recording_studio_duplicatable/services/base_service"
require "recording_studio_duplicatable/capabilities/duplicatable"
require "recording_studio_duplicatable/services/duplication_service"

module RecordingStudioDuplicatable
  class MissingDependencyError < StandardError; end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def authorized?(actor:, recording:, role:)
      authorization_resolver!.call(actor: actor, recording: recording, role: role)
    end

    def ensure_current_impersonator_attribute!
      return unless defined?(Current) && Current.respond_to?(:attribute)
      return if Current.respond_to?(:impersonator) && Current.respond_to?(:impersonator=)

      Current.attribute :impersonator
    end

    def configure
      yield(configuration) if block_given?
    end

    private

    def authorization_resolver!
      return configuration.authorization_resolver if configuration.authorization_resolver

      raise_accessible_missing_dependency! unless accessible_authorization_available?

      method(:accessible_authorization_allowed?)
    end

    def accessible_authorization_available?
      return false unless defined?(RecordingStudioAccessible)
      return false unless access_check_service_available?

      accessible_owns_access_check_service?
    end

    def accessible_authorization_allowed?(actor:, recording:, role:)
      RecordingStudio::Services::AccessCheck.allowed?(
        actor: actor,
        recording: recording,
        role: role
      )
    end

    def accessible_owns_access_check_service?
      compatibility = nil

      if RecordingStudioAccessible.const_defined?(:Compatibility, false)
        compatibility = RecordingStudioAccessible.const_get(:Compatibility)
      end

      return compatibility.access_check_owned_by_addon? if compatibility.respond_to?(:access_check_owned_by_addon?)

      access_check_source_locations.any? do |path|
        path.include?("/recording_studio_accessible/") || path.include?("\\recording_studio_accessible\\")
      end
    end

    def access_check_service_available?
      defined?(RecordingStudio::Services::AccessCheck) &&
        RecordingStudio::Services::AccessCheck.respond_to?(:allowed?)
    end

    def access_check_source_locations
      [
        RecordingStudio::Services::AccessCheck.method(:allowed?).source_location&.first,
        RecordingStudio::Services::AccessCheck.instance_method(:perform).source_location&.first
      ].compact
    rescue NameError
      []
    end

    def raise_accessible_missing_dependency!
      raise MissingDependencyError,
            "recording_studio_accessible must be installed, loaded, and provide " \
            "authorization for RecordingStudioDuplicatable before duplication can run"
    end
  end
end
