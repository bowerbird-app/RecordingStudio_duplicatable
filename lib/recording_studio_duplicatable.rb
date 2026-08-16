# frozen_string_literal: true

begin
  require "recording_studio"
rescue LoadError
  nil
end

begin
  require "recording_studio_accessible"
rescue LoadError
  nil
end

require "recording_studio_duplicatable/version"
require "recording_studio_duplicatable/engine"
require "recording_studio_duplicatable/configuration"
require "recording_studio_duplicatable/services/base_service"
require "recording_studio_duplicatable/capabilities/duplicatable"
require "recording_studio_duplicatable/services/duplication_service"
require "recording_studio_duplicatable/api"

module RecordingStudioDuplicatable
  access_denied_superclass = defined?(::RecordingStudio::AccessDenied) ? ::RecordingStudio::AccessDenied : StandardError
  AccessDenied = Class.new(access_denied_superclass) unless const_defined?(:AccessDenied, false)
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
      defined?(RecordingStudioAccessible) && RecordingStudioAccessible.respond_to?(:authorized?)
    end

    def accessible_authorization_allowed?(actor:, recording:, role:)
      RecordingStudioAccessible.authorized?(
        actor: actor,
        recording: recording,
        role: role
      )
    end

    def raise_accessible_missing_dependency!
      raise MissingDependencyError,
            "recording_studio_accessible must be installed and loaded so " \
            "RecordingStudioDuplicatable can authorize duplication through " \
            "RecordingStudioAccessible.authorized?"
    end
  end
end
