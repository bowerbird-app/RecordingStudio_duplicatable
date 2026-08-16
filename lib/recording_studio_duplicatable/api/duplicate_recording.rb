# frozen_string_literal: true

module RecordingStudioDuplicatable
  module Api
    class DuplicateRecording
      OPTIONAL_DUPLICATE_KEYS = %i[prefix suffix include_children exclude_children].freeze

      def self.call(context)
        new(context).call
      end

      def initialize(context)
        @context = context
      end

      def call
        ensure_duplicate_supported!
        authorize_duplicate!
        duplicate!
      end

      private

      attr_reader :context

      def authorize_duplicate!
        recordings_to_authorize.each do |recording|
          context.access_grant.authorize!(recording: recording, role: :edit)
        end
      end

      def recordings_to_authorize
        [context.recording, context.recording.try(:parent_recording)].compact.uniq
      end

      def duplicate!
        perform_duplicate!
      rescue StandardError => e
        mapped = mapped_duplicate_error(e)
        raise mapped if mapped

        raise
      end

      def perform_duplicate!
        context.recording.duplicate_in_place!(**duplicate_kwargs)
      end

      def ensure_duplicate_supported!
        return if context.recording.respond_to?(:duplicate_in_place!)

        raise RecordingStudioApi::UnsupportedActionError,
              "Duplicate is not supported for #{context.recording.recordable_type}"
      end

      def duplicate_kwargs
        kwargs = {
          actor: context.api_client,
          metadata: duplicate_metadata
        }

        OPTIONAL_DUPLICATE_KEYS.each do |key|
          kwargs[key] = parameter_value(key) if params_key?(key)
        end

        kwargs
      end

      def duplicate_metadata
        {
          api_action: "duplicate",
          api_client_id: context.api_client.id,
          api_credential_id: context.credential.id
        }
      end

      def params_key?(key)
        return false unless context.params.respond_to?(:key?)

        context.params.key?(key) || context.params.key?(key.to_s)
      end

      def parameter_value(key)
        return unless context.params.respond_to?(:[])

        context.params[key] || context.params[key.to_s]
      end

      def mapped_duplicate_error(error)
        return RecordingStudioApi::AuthorizationError.new(error.message) if access_denied_error?(error)
        return RecordingStudioApi::UnsupportedActionError.new(error.message) if unsupported_duplicate_error?(error)
        return invalid_duplicate_input_error(error) if invalid_record_error?(error)

        nil
      end

      def access_denied_error?(error)
        return true if error.is_a?(RecordingStudioDuplicatable::AccessDenied)

        defined?(RecordingStudio::AccessDenied) && error.is_a?(RecordingStudio::AccessDenied)
      end

      def unsupported_duplicate_error?(error)
        return true if error.is_a?(RecordingStudioDuplicatable::MissingDependencyError)

        defined?(RecordingStudio::CapabilityDisabled) && error.is_a?(RecordingStudio::CapabilityDisabled)
      end

      def invalid_record_error?(error)
        defined?(ActiveRecord::RecordInvalid) && error.is_a?(ActiveRecord::RecordInvalid)
      end

      def invalid_duplicate_input_error(error)
        RecordingStudioApi::InvalidActionInputError.new(error.message, details: [error.message])
      end
    end
  end
end
