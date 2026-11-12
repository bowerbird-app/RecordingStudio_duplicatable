# frozen_string_literal: true

module RecordingStudio
  module Duplicatable
    module Api
      class DuplicateRecording
        def self.call(context)
          new(context).call
        end

        def initialize(context)
          @context = context
        end

        def call
          recording = find_recording_in_grant_root!
          ensure_duplicate_supported!(recording)
          context.access_grant.authorize!(recording: recording, role: :edit)
          duplicate!(recording)
        end

        private

        attr_reader :context

        def find_recording_in_grant_root!
          recording_id = context.recording.id
          recording = context.access_grant.accessible_recordings.find_by(id: recording_id)
          return recording if recording

          raise RecordingStudioApi::NotFoundError, "Recording was not found in this API scope"
        end

        def ensure_duplicate_supported!(recording)
          return if recording.respond_to?(:duplicate_in_place!)

          raise RecordingStudioApi::UnsupportedActionError,
                "Duplicate is not supported for #{recording.recordable_type}"
        end

        def duplicate!(recording)
          result = RecordingStudioDuplicatable::Services::DuplicationService.call(
            recording: recording,
            actor: context.access_grant.actor,
            metadata: duplicate_metadata
          )
          return result.value if result.success?

          raise_api_error!(result.error)
        end

        def raise_api_error!(error)
          message = error.to_s
          case message
          when "Actor does not have :edit access for duplication"
            raise RecordingStudioApi::AuthorizationError, message
          when /capability/i
            raise RecordingStudioApi::UnsupportedActionError, message
          else
            raise RecordingStudioApi::InvalidActionInputError, message
          end
        end

        def duplicate_metadata
          metadata = {
            api_action: "duplicate",
            api_client_id: context.api_client.id,
            api_credential_id: context.credential.id
          }
          return metadata unless context.respond_to?(:with_authorized_by)

          context.with_authorized_by(metadata)
        end
      end
    end
  end
end
