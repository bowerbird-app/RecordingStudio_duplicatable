# frozen_string_literal: true

require "recording_studio_duplicatable/api/duplicate_recording"

module RecordingStudioDuplicatable
  module Api
    ACTION_VERSION = "1.0.0"
    INTERNAL_ROUTE_PARAMETER_KEYS = %i[api_key api_version].push("api_key", "api_version").freeze

    class << self
      def register_capability_action!
        return unless recording_studio_api_available?

        if named_api_registration_supported?
          RecordingStudioApi.configuration.each_api do |api_definition|
            register_capability_action_for(api_definition.name)
          end
        elsif !RecordingStudioApi.capability_action(:duplicate)
          RecordingStudioApi.register_capability_action(:duplicate, **capability_action_options)
        end
      end

      private

      def register_capability_action_for(api_name)
        return if RecordingStudioApi.capability_action(:duplicate, api: api_name)

        RecordingStudioApi.register_capability_action(:duplicate, api: api_name, **capability_action_options)
      end

      def named_api_registration_supported?
        RecordingStudioApi.respond_to?(:configuration) &&
          RecordingStudioApi.configuration.respond_to?(:each_api) &&
          action_api_accepts_api?(:capability_action) &&
          action_api_accepts_api?(:register_capability_action)
      end

      def action_api_accepts_api?(method_name)
        RecordingStudioApi.method(method_name).parameters.any? do |type, name|
          type == :keyrest || (name == :api && %i[key keyreq].include?(type))
        end
      end

      def capability_action_options
        action_metadata.merge(
          handler: DuplicateRecording,
          serializer: RecordingStudioApi::Serializers::ResourceRecordingSerializer,
          input_contract: duplicate_input_contract,
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

      def duplicate_input_contract
        definition = {
          reject_unknown: true,
          fields: {
            prefix: { type: :string, required: false },
            suffix: { type: :string, required: false },
            include_children: { type: :array, required: false },
            exclude_children: { type: :array, required: false }
          }
        }

        return definition unless defined?(RecordingStudioApi::ActionInputContract)

        route_parameter_filtering_contract.new(definition)
      end

      def route_parameter_filtering_contract
        # API 0.2 forwards these named-route keys to action contracts. Filter
        # them here because declared contract fields become OpenAPI body fields.
        Class.new(RecordingStudioApi::ActionInputContract) do
          define_method(:call) do |raw_params|
            params = raw_params.respond_to?(:to_h) ? raw_params.to_h : raw_params
            if params.respond_to?(:except)
              params = params.except(*RecordingStudioDuplicatable::Api::INTERNAL_ROUTE_PARAMETER_KEYS)
            end
            super(params)
          end
        end
      end

      def duplicate_openapi
        {
          summary: "Duplicate",
          description: "Duplicates the recording in place under the same parent, " \
                       "using the recordable type's duplicatable options unless overrides are supplied.",
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
