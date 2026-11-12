# frozen_string_literal: true

return unless defined?(RecordingStudioApi)

RecordingStudioApi.configure do |config|
  config.rate_limit_oauth_enabled = false
  config.rate_limit_api_pre_auth_enabled = false
  config.rate_limit_api_enabled = false
  config.rate_limit_fail_closed = false
  config.api_management_authorization_required = false
  config.admin_root_recordable_type_names = []
end

%w[Page Report Folder].each do |type|
  next if RecordingStudioApi.recordable_registration_for(type)

  RecordingStudioApi.register_recordable_type_api(
    type,
    serializer: lambda { |recordable, **|
      {
        title: recordable.try(:title),
        name: recordable.try(:name),
        slug: recordable.try(:slug)
      }
    },
    output_keys: %i[title name slug],
    operations: %i[show]
  )
end
