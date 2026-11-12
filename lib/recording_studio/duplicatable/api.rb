# frozen_string_literal: true

require "recording_studio/duplicatable/api/duplicate_recording"

module RecordingStudio
  module Duplicatable
    module Api
      ACTION_VERSION = "1.0.0"

      class << self
        def register_capability_action!
          return unless recording_studio_api_available?

          RecordingStudioApi.configuration.each_api do |api_definition|
            next if RecordingStudioApi.capability_action(:duplicate, api: api_definition.name)

            RecordingStudioApi.register_capability_action(
              :duplicate,
              api: api_definition.name,
              **capability_action_options
            )
          end
        end

        private

        def capability_action_options
          action_metadata.merge(
            handler: DuplicateRecording,
            serializer: RecordingStudioApi::Serializers::ResourceRecordingSerializer,
            input_contract: { reject_unknown: false, fields: {} },
            openapi: duplicate_openapi
          )
        end

        def action_metadata
          {
            capability: :duplicatable,
            version: ACTION_VERSION,
            version_notes: ["Duplicatable-owned duplicate action"],
            http_verb: :post,
            scope: :member,
            required_role: :edit
          }
        end

        def recording_studio_api_available?
          defined?(RecordingStudioApi) &&
            RecordingStudioApi.respond_to?(:capability_action) &&
            RecordingStudioApi.respond_to?(:register_capability_action) &&
            defined?(RecordingStudioApi::Serializers::ResourceRecordingSerializer)
        end

        def duplicate_openapi
          {
            summary: "Duplicates this recording in place under the same parent.",
            description: "Creates a duplicate of the recording under the same parent.",
            responses: {
              "200" => { description: "Recording duplicated successfully." },
              "403" => { description: "API access is not authorized to duplicate this recording." },
              "422" => { description: "Duplicate request is invalid." }
            }
          }
        end
      end
    end
  end
end
