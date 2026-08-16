# frozen_string_literal: true

require "test_helper"

class DuplicatableApiTest < Minitest::Test
  ActionContext = Struct.new(:recording, :api_client, :credential, :access_grant, :params, keyword_init: true)
  ApiPrincipal = Struct.new(:id)

  class AccessGrant
    attr_reader :authorized_recordings

    def initialize
      @authorized_recordings = []
    end

    def authorize!(recording:, role:)
      authorized_recordings << [recording, role]
    end
  end

  class Recording
    attr_reader :recordable_type, :parent_recording, :duplicated_with, :duplicate

    def initialize(recordable_type: "Page", parent_recording: nil, duplicate_error: nil, duplicate: nil)
      @recordable_type = recordable_type
      @parent_recording = parent_recording
      @duplicate_error = duplicate_error
      @duplicate = duplicate || self
    end

    def duplicate_in_place!(**kwargs)
      raise @duplicate_error if @duplicate_error

      @duplicated_with = kwargs
      @duplicate
    end
  end

  def test_registration_is_a_noop_without_recording_studio_api
    refute Object.const_defined?(:RecordingStudioApi, false)

    assert_nil RecordingStudioDuplicatable::Api.register_capability_action!
  end

  def test_registration_registers_duplicatable_owned_member_action
    with_fake_recording_studio_api do |api|
      RecordingStudioDuplicatable::Api.register_capability_action!

      registration = api.registrations.fetch(0)

      assert_equal :duplicate, registration.fetch(:name)
      assert_equal :duplicatable, registration.fetch(:capability)
      assert_equal "1.0.0", registration.fetch(:version)
      assert_equal ["Duplicatable-owned duplicate action"], registration.fetch(:version_notes)
      assert_equal :post, registration.fetch(:http_verb)
      assert_equal :member, registration.fetch(:scope)
      assert_equal :edit, registration.fetch(:required_role)
      assert_equal RecordingStudioDuplicatable::Api::DuplicateRecording, registration.fetch(:handler)
      assert_equal api.serializer, registration.fetch(:serializer)
      refute registration.fetch(:openapi).key?(:tags)
      assert_equal "Duplicate", registration.fetch(:openapi).fetch(:summary)
      assert_equal expected_input_contract, registration.fetch(:input_contract)
    end
  end

  def test_registration_does_not_replace_an_existing_duplicate_action
    existing_action = Object.new

    with_fake_recording_studio_api(existing_action:) do |api|
      assert_nil RecordingStudioDuplicatable::Api.register_capability_action!
      assert_empty api.registrations
    end
  end

  def test_registration_registers_public_and_named_api_surfaces_independently
    with_fake_recording_studio_api(api_names: %w[public operations partners]) do |api|
      RecordingStudioDuplicatable::Api.register_capability_action!
      registered_apis = api.registrations.map { |registration| registration.fetch(:api) }

      assert_equal %w[public operations partners], registered_apis
    end
  end

  def test_registration_does_not_replace_existing_actions_on_any_api_surface
    existing_actions = {
      "public" => Object.new,
      "operations" => Object.new
    }

    with_fake_recording_studio_api(api_names: %w[public operations partners], existing_actions:) do |api|
      RecordingStudioDuplicatable::Api.register_capability_action!
      registered_apis = api.registrations.map { |registration| registration.fetch(:api) }

      assert_equal ["partners"], registered_apis
    end
  end

  def test_api_0_2_input_contract_filters_internal_string_and_symbol_keys
    with_fake_recording_studio_api(api_names: %w[public]) do |api|
      RecordingStudioDuplicatable::Api.register_capability_action!
      contract = api.registrations.fetch(0).fetch(:input_contract)

      assert_operator contract.class, :<, api.action_input_contract

      result = contract.call("suffix" => " (Copy)", "api_key" => "public", api_version: "v1")

      assert result.success?, result.errors.join(", ")
      assert_equal({ suffix: " (Copy)" }, result.value)

      unknown_result = contract.call(suffix: " (Copy)", api_key: "public", "api_version" => "v1", extra: true)

      refute unknown_result.success?
      assert_equal ["Unknown parameters: extra"], unknown_result.errors
    end
  end

  def test_handler_authorizes_source_and_parent_then_duplicates
    parent = Recording.new(recordable_type: "Workspace")
    duplicate = Recording.new(recordable_type: "Page")
    source = Recording.new(parent_recording: parent, duplicate:)
    access_grant = AccessGrant.new
    client = ApiPrincipal.new("client-1")
    credential = ApiPrincipal.new("credential-1")

    with_fake_recording_studio_api do
      result = RecordingStudioDuplicatable::Api::DuplicateRecording.call(
        action_context(
          source:,
          access_grant:,
          client:,
          credential:,
          params: {}
        )
      )

      assert_same duplicate, result
      assert_equal [[source, :edit], [parent, :edit]], access_grant.authorized_recordings
      assert_equal(
        {
          actor: client,
          metadata: {
            api_action: "duplicate",
            api_client_id: "client-1",
            api_credential_id: "credential-1"
          }
        },
        source.duplicated_with
      )
    end
  end

  def test_handler_passes_optional_duplicate_overrides
    source = Recording.new

    with_fake_recording_studio_api do
      RecordingStudioDuplicatable::Api::DuplicateRecording.call(
        action_context(
          source:,
          access_grant: AccessGrant.new,
          params: {
            prefix: "Copy of ",
            suffix: nil,
            include_children: ["Comment"],
            exclude_children: ["Report"]
          }
        )
      )
    end

    assert_equal "Copy of ", source.duplicated_with.fetch(:prefix)
    assert_nil source.duplicated_with.fetch(:suffix)
    assert_equal ["Comment"], source.duplicated_with.fetch(:include_children)
    assert_equal ["Report"], source.duplicated_with.fetch(:exclude_children)
  end

  def test_handler_rejects_recordings_without_duplicatable_behavior
    unsupported_recording = Struct.new(:recordable_type, :parent_recording).new("Comment", nil)

    with_fake_recording_studio_api do |api|
      error = assert_raises(api.unsupported_action_error) do
        RecordingStudioDuplicatable::Api::DuplicateRecording.call(
          action_context(
            source: unsupported_recording,
            access_grant: AccessGrant.new,
            params: {}
          )
        )
      end

      assert_equal "Duplicate is not supported for Comment", error.message
    end
  end

  def test_handler_translates_access_denied_without_mutation
    source = Recording.new(
      duplicate_error: RecordingStudioDuplicatable::AccessDenied.new("Actor does not have :edit access for duplication")
    )

    with_fake_recording_studio_api do |api|
      error = assert_raises(api.authorization_error) do
        RecordingStudioDuplicatable::Api::DuplicateRecording.call(
          action_context(source:, access_grant: AccessGrant.new, params: {})
        )
      end

      assert_equal "Actor does not have :edit access for duplication", error.message
      assert_nil source.duplicated_with
    end
  end

  def test_handler_translates_capability_disabled_without_mutation
    skip unless defined?(RecordingStudio::CapabilityDisabled)

    source = Recording.new(
      duplicate_error: RecordingStudio::CapabilityDisabled.new("duplicatable is not enabled")
    )

    with_fake_recording_studio_api do |api|
      error = assert_raises(api.unsupported_action_error) do
        RecordingStudioDuplicatable::Api::DuplicateRecording.call(
          action_context(source:, access_grant: AccessGrant.new, params: {})
        )
      end

      assert_equal "duplicatable is not enabled", error.message
      assert_nil source.duplicated_with
    end
  end

  def test_handler_translates_missing_dependency_without_mutation
    source = Recording.new(
      duplicate_error: RecordingStudioDuplicatable::MissingDependencyError.new(
        "recording_studio_accessible must be installed"
      )
    )

    with_fake_recording_studio_api do |api|
      error = assert_raises(api.unsupported_action_error) do
        RecordingStudioDuplicatable::Api::DuplicateRecording.call(
          action_context(source:, access_grant: AccessGrant.new, params: {})
        )
      end

      assert_equal "recording_studio_accessible must be installed", error.message
      assert_nil source.duplicated_with
    end
  end

  def test_handler_preserves_unrecognized_errors
    source = Recording.new(duplicate_error: ArgumentError.new("unexpected duplicate failure"))

    with_fake_recording_studio_api do
      error = assert_raises(ArgumentError) do
        RecordingStudioDuplicatable::Api::DuplicateRecording.call(
          action_context(source:, access_grant: AccessGrant.new, params: {})
        )
      end

      assert_equal "unexpected duplicate failure", error.message
      assert_nil source.duplicated_with
    end
  end

  private

  def expected_input_contract
    {
      reject_unknown: true,
      fields: {
        prefix: { type: :string, required: false },
        suffix: { type: :string, required: false },
        include_children: { type: :array, required: false },
        exclude_children: { type: :array, required: false }
      }
    }
  end

  def action_context(source:, access_grant:, params:, client: ApiPrincipal.new("client-1"),
                     credential: ApiPrincipal.new("credential-1"))
    ActionContext.new(
      recording: source,
      api_client: client,
      credential: credential,
      access_grant:,
      params:
    )
  end

  def with_fake_recording_studio_api(existing_action: nil, existing_actions: {}, api_names: nil)
    api = Module.new
    serializers = Module.new
    serializer = Class.new
    invalid_action_input_error = Class.new(StandardError) do
      attr_reader :details

      def initialize(message, details: [])
        super(message)
        @details = details
      end
    end

    serializers.const_set(:ResourceRecordingSerializer, serializer)
    api.const_set(:Serializers, serializers)
    api.const_set(:UnsupportedActionError, Class.new(StandardError))
    api.const_set(:InvalidActionInputError, invalid_action_input_error)
    api.const_set(:AuthorizationError, Class.new(StandardError))
    api.const_set(:NotFoundError, Class.new(StandardError))
    api.instance_variable_set(:@existing_action, existing_action)
    api.instance_variable_set(:@existing_actions, existing_actions.transform_keys(&:to_s))
    api.instance_variable_set(:@registrations, [])
    api.instance_variable_set(:@serializer, serializer)

    if api_names
      define_api_0_2_behavior(api, api_names)
    else
      api.define_singleton_method(:capability_action) { |name| @existing_action if name == :duplicate }
      api.define_singleton_method(:register_capability_action) do |name, **options|
        @registrations << options.merge(name:)
      end
    end

    api.define_singleton_method(:registrations) { @registrations }
    api.define_singleton_method(:serializer) { @serializer }
    api.define_singleton_method(:action_input_contract) { const_get(:ActionInputContract) }
    api.define_singleton_method(:unsupported_action_error) { const_get(:UnsupportedActionError) }
    api.define_singleton_method(:invalid_action_input_error) { const_get(:InvalidActionInputError) }
    api.define_singleton_method(:authorization_error) { const_get(:AuthorizationError) }
    api.define_singleton_method(:not_found_error) { const_get(:NotFoundError) }

    Object.const_set(:RecordingStudioApi, api)
    yield api
  ensure
    Object.send(:remove_const, :RecordingStudioApi) if Object.const_defined?(:RecordingStudioApi, false)
  end

  def define_api_0_2_behavior(api, api_names)
    configuration = fake_api_configuration(api_names)

    api.const_set(:ActionInputContract, fake_action_input_contract_class)
    api.define_singleton_method(:configuration) { configuration }
    api.define_singleton_method(:capability_action) do |name, api: :public|
      @existing_actions[api.to_s] if name == :duplicate
    end
    api.define_singleton_method(:register_capability_action) do |name, api: :public, **options|
      @registrations << options.merge(name:, api: api.to_s)
    end
  end

  def fake_action_input_contract_class
    contract_result = Struct.new(:success?, :value, :errors, keyword_init: true)
    Class.new do
      define_method(:initialize) do |definition|
        @definition = definition
        @fields = definition.fetch(:fields).keys.map(&:to_sym)
      end

      define_method(:call) do |raw_params|
        params = raw_params.to_h.transform_keys(&:to_sym)
        unknown_keys = params.keys - @fields
        errors = unknown_keys.empty? ? [] : ["Unknown parameters: #{unknown_keys.sort.join(', ')}"]
        value = errors.empty? ? params.slice(*@fields) : nil
        contract_result.new(success?: errors.empty?, value:, errors:)
      end

      define_method(:as_json) { |*| @definition }
    end
  end

  def fake_api_configuration(api_names)
    definitions = api_names.map { |name| Struct.new(:name).new(name.to_s) }
    Struct.new(:definitions) do
      def each_api(&)
        definitions.each(&)
      end
    end.new(definitions)
  end
end
