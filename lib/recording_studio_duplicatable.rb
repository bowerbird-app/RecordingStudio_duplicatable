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

    def configure
      yield(configuration) if block_given?
    end
  end
end
