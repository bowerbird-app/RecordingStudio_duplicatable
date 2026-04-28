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

    def access_check_service!
      raise_accessible_missing_dependency! unless defined?(RecordingStudioAccessible)
      return RecordingStudio::Services::AccessCheck if access_check_service_available?

      raise MissingDependencyError,
            "recording_studio_accessible did not provide RecordingStudio::Services::AccessCheck.allowed?"
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

    def access_check_service_available?
      defined?(RecordingStudio::Services::AccessCheck) &&
        RecordingStudio::Services::AccessCheck.respond_to?(:allowed?)
    end

    def raise_accessible_missing_dependency!
      raise MissingDependencyError,
            "recording_studio_accessible must be installed and loaded before using " \
            "RecordingStudioDuplicatable access checks"
    end
  end
end
