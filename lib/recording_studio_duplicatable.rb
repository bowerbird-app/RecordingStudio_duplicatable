# frozen_string_literal: true

require "recording_studio_duplicatable/version"
require "recording_studio_duplicatable/engine"
require "recording_studio_duplicatable/configuration"
require "recording_studio_duplicatable/services/base_service"
require "recording_studio_duplicatable/capabilities/duplicatable"
require "recording_studio_duplicatable/services/duplication_service"

module RecordingStudioDuplicatable
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def ensure_current_impersonator_attribute!
      return unless defined?(Current) && Current.respond_to?(:attribute)
      return if Current.respond_to?(:impersonator) && Current.respond_to?(:impersonator=)

      Current.attribute :impersonator
    end

    def configure
      yield(configuration) if block_given?
    end
  end
end
