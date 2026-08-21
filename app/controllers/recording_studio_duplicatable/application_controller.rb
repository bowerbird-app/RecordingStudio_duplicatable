# frozen_string_literal: true

module RecordingStudioDuplicatable
  class ApplicationController < (defined?(::ApplicationController) ? ::ApplicationController : ActionController::Base)
    protect_from_forgery with: :exception
    if defined?(RecordingStudio::UsesDefaultLayout)
      include RecordingStudio::UsesDefaultLayout
    else
      layout "application"
    end

    private

    def current_duplication_actor
      resolve_recording_studio_actor || resolve_current_actor
    end

    def current_duplication_impersonator
      resolve_recording_studio_impersonator || resolve_current_impersonator
    end

    def resolve_recording_studio_impersonator
      return unless defined?(RecordingStudio)
      return unless RecordingStudio.respond_to?(:configuration)

      configuration = RecordingStudio.configuration
      return unless configuration.respond_to?(:impersonator)

      resolve_callable(configuration.impersonator)
    end

    def resolve_current_impersonator
      return unless defined?(Current)
      return unless Current.respond_to?(:impersonator)

      Current.impersonator
    end

    def resolve_recording_studio_actor
      return unless defined?(RecordingStudio)
      return unless RecordingStudio.respond_to?(:configuration)

      configuration = RecordingStudio.configuration
      return unless configuration.respond_to?(:actor)

      resolve_callable(configuration.actor)
    end

    def resolve_current_actor
      return unless defined?(Current)
      return unless Current.respond_to?(:actor)

      Current.actor
    end

    def resolve_callable(callable)
      return callable unless callable.respond_to?(:call)

      if callable.arity == 1
        callable.call(self)
      else
        instance_exec(&callable)
      end
    rescue ArgumentError
      callable.call
    end
  end
end
