> **Architecture Documentation**
> *   **Canonical Source:** [bowerbird-app/RecordingStudio_duplicatable](https://github.com/bowerbird-app/RecordingStudio_duplicatable/tree/main/docs/recording_studio_duplicatable)
> *   **Last Updated:** August 16, 2026
>
> *Maintainers: Please update the date above when modifying this file.*

---

# Optional Recording Studio API Action

`recording_studio_duplicatable` works without `recording_studio_api`. When the host application installs
Recording Studio API, Duplicatable registers a member `duplicate` action for the `:duplicatable`
capability during engine initialization. With Recording Studio API 0.2.0 and later, it registers the
action independently in the public API and every configured named API without replacing actions
already registered by the host or another addon.

The action contract is version `1.0.0`, uses `POST`, and requires `:edit`. A surface exposes it only
when the recordable type enables `:duplicatable` **and** that API surface's recordable-type
registration explicitly allowlists `:duplicate`.

## Enable Duplicatable on Source Types

Each type that should be duplicatable through the API must include the Duplicatable capability. The
API action is available only for these source types:

```ruby
class Page < ApplicationRecord
  recording_studio_recordable(
    label: "Page",
    root: false,
    allowed_parent_types: ["Workspace"]
  )

  include RecordingStudioDuplicatable::Capabilities::Duplicatable.with(
    prefix: nil,
    suffix: " (Copy)",
    include_children: ["Comment"]
  )
end
```

An empty request body uses those type defaults. Optional `prefix`, `suffix`, `include_children`, and
`exclude_children` fields override them for that request.

## Install the Optional API Engine

Add the API gem to the **host application's** `Gemfile`. It is intentionally not a runtime
dependency of this gem.

```ruby
gem "recording_studio_api", github: "bowerbird-app/RecordingStudio_api", tag: "0.4.0"
```

Then run the API generators from the host application directory:

```bash
bin/rails generate recording_studio_api:install
bin/rails generate recording_studio_api:migrations
bin/rails db:migrate
```

Enable both `:accessible` and `:api_access_point` on each root type that may receive API access:

```ruby
RecordingStudio.enable_capability(:accessible, on: Workspace)
RecordingStudio.enable_capability(:api_access_point, on: Workspace)
```

## Configure an API Version Profile

Without a version profile, Recording Studio API selects the current `duplicate` action automatically.
A host that publishes version profiles should explicitly select the Duplicatable contract:

```ruby
# config/initializers/recording_studio_api.rb
RecordingStudioApi.configure do |config|
  config.api_versions = %w[v1]
  config.default_api_version = "v1"

  config.version "v1" do |api|
    api.use :duplicatable, "~> 1.0"
  end
end

RecordingStudioApi.register_recordable_type_api(
  "Page",
  capability_actions: %i[duplicate]
)
RecordingStudioApi.register_recordable_type_api(
  "Folder",
  capability_actions: %i[duplicate]
)
```

Recording Studio API uses a default-deny allowlist for custom capability actions. Register
`:duplicate` only for the types that should publish Duplicatable's action. The underlying
`:duplicatable` capability and the API authorization checks are still required.

Named APIs have independent action and type registries. Configure the named surface and allowlist
`:duplicate` on that surface explicitly:

```ruby
RecordingStudioApi.configure do |config|
  config.api :operations do |api|
    api.api_versions = %w[v1]
    api.default_api_version = "v1"

    api.version "v1" do |version|
      version.use :duplicatable, "~> 1.0"
    end
  end
end

RecordingStudioApi.register_recordable_type_api(
  "Page",
  api: :operations,
  capability_actions: %i[duplicate]
)
```

This named allowlist does not expose `:duplicate` on `public`, and the public allowlist does not
expose it on `:operations`.

## Endpoint and Input

For a duplicatable `Page`, clients call:

```http
POST /recording_studio_api/api/v1/pages/:id/actions/duplicate
Content-Type: application/json
Authorization: ******

{ "suffix": " (Copy)" }
```

All fields are optional. Unknown keys are rejected. The handler authorizes `:edit` access to the
source and its parent, then calls `duplicate_in_place!` with the API client as actor. It records the
API action, API client ID, and credential ID as duplication metadata and returns the new recording
for API serialization.

Authorization failures return `403 Forbidden`. Capability or dependency failures return as an
unsupported action. Record validation failures return `422 Unprocessable Entity`.

Recording Studio API also supports the compatibility alias:

```text
POST /recording_studio_api/api/v1/pages/:id/duplicate
```

## Related API Documentation

- [Capability-backed actions](https://github.com/bowerbird-app/RecordingStudio_api#capability-backed-actions)
- [Versioning model](https://github.com/bowerbird-app/RecordingStudio_api#versioning-model)
- [API endpoints](https://github.com/bowerbird-app/RecordingStudio_api#api-endpoints)
