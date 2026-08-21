# RecordingStudio Duplicatable

`RecordingStudio Duplicatable` is a Rails engine addon that adds a simple, opt-in duplication capability to Recording Studio recordables.

## What it does

- Registers a `:duplicatable` capability with Recording Studio
- Lets recordable models opt in explicitly
- Duplicates a recording in place under the same parent
- Renames the duplicate with configurable prefix/suffix rules
- Recursively duplicates descendant recordings when child copying is enabled
- Uses Recording Studio Accessible for duplication authorization while preserving parent/root recording relationships
- Ships with a built-in duplication controller and route for simple buttons/links
- Exposes a small controller-friendly `DuplicationService`

## Installation

Add Recording Studio core, Recording Studio Accessible, and this addon to your host app:

```ruby
gem "recording_studio", github: "bowerbird-app/RecordingStudio", tag: "v4.2.0"
gem "recording_studio_accessible", github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.6.0"
gem "recording_studio_duplicatable", github: "bowerbird-app/RecordingStudio_duplicatable"
```

Then run the installer if you want the initializer, YAML config, mount, and Tailwind source hints:

```bash
bundle install
bin/rails generate recording_studio:install
bin/rails generate recording_studio:migrations
bin/rails generate recording_studio_accessible:install
bin/rails generate recording_studio_accessible:migrations
bin/rails generate recording_studio_duplicatable:install
bin/rails db:migrate
```

The installer mounts the engine so host app views can use the built-in duplicate endpoint.
Install and configure `recording_studio_accessible` before using duplication so authorization is provided by `RecordingStudioAccessible.authorized?` from the extracted access addon.
Configure `RecordingStudioAccessible.configure { |c| c.access_actor_types = ["User"] }` (or your actor types) before granting access — blank allowlists reject new grants since Accessible 0.5.0.
If Recording Studio Accessible adds migrations for your app, make sure those migrations are installed and applied before you use duplication.
RecordingStudio 4 also installs a harden migration for unique root recordings and composite indexes — run `recording_studio:migrations` and migrate before relying on writes under concurrency.

## Opting a model into duplication

Installing this gem does not enable duplication. Opt each recordable type in
with one host verb:

```ruby
class Page < ApplicationRecord
  recording_studio_recordable label: "Page", root: false, allowed_parent_types: ["Workspace"]
  RecordingStudio.enable_capability(:accessible, on: self)

  include RecordingStudio::Capabilities::Duplicatable.to(
    prefix: nil,
    suffix: " (Copy)",
    include_children: ["Comment"],
    exclude_children: nil
  )
end
```

`.to` is a thin wrapper around `RecordingStudio::Capabilities.include_for(:duplicatable, **options)`.
Parent rules stay on `recording_studio_recordable`. Option validation for `prefix:`, `suffix:`,
`include_children:`, and `exclude_children:` stays in this gem.

Bare `include RecordingStudioDuplicatable::Capabilities::Duplicatable` and `.with(...)` still work
as aliases of `.to`.

## Configuration

Global defaults:

```ruby
RecordingStudioDuplicatable.configure do |config|
  config.duplication_prefix = nil
  config.duplication_suffix = " (Copy)"
  config.duplication_rename_attribute = nil
end
```

Recording Studio 4 requires every configured recordable to declare its hierarchy.
Root recordables use `root: true`; child recordables use `root: false` with
`allowed_parent_types`. Enable `:accessible` on recordables that should accept
direct access grants from Recording Studio Accessible.

Available options:

| Option | Description |
|---|---|
| `duplication_prefix` | Prefix added to a duplicate name/title |
| `duplication_suffix` | Suffix added to a duplicate name/title |
| `duplication_rename_attribute` | Force the rename attribute instead of auto-detecting `name`/`title` |
| `include_children` | Only duplicate descendants of these recordable types |
| `exclude_children` | Duplicate descendants except these recordable types |

## Usage

### Built-in controller and route

Once the engine is mounted, host app views can post directly to the gem:

```erb
<%= button_to "Duplicate",
  recording_studio_duplicatable.duplicate_recording_path(recording_id: recording.id),
  method: :post %>
```

The built-in controller:

- resolves the actor from your existing Recording Studio actor setup
- falls back to `Current.actor` when needed
- resolves the impersonator from your Recording Studio impersonator setup
- falls back to `Current.impersonator` when needed
- relies on the existing duplication API, which performs the standard `RecordingStudioAccessible.authorized?` duplication authorization check
- redirects back with a notice or alert

Make sure your host app keeps Recording Studio configured with the current actor, for example:

```ruby
RecordingStudio.configure do |config|
  config.actor = -> { Current.actor }
  config.impersonator = -> { Current.impersonator }
  config.require_recordable_declarations = true
end
```

The engine controller inherits from your host app `ApplicationController` when one is present, so existing authentication and current-actor callbacks continue to apply.

### Direct recording API

Duplicate from a recording when you want custom controller behavior:

```ruby
new_recording = recording.duplicate_in_place!(
  actor: current_user
)
```

### Service object

Or use the service object in your own controller/service:

```ruby
result = RecordingStudioDuplicatable::Services::DuplicationService.call(
  recording: recording,
  actor: current_user
)
```

The lower-level recording and service APIs remain available for apps that want custom redirects, response formats, or extra side effects.

## Behavior notes

- Duplication is wrapped in a transaction with row locking
- The actor must be authorized by `RecordingStudioAccessible.authorized?` to duplicate the target recording
- The capability must be enabled for the recordable type
- Child-copy filters apply recursively through the descendant tree
- Post-duplication callbacks and hooks run after the transaction completes

## Dummy app

The dummy app in `test/dummy/` demonstrates:

- Devise authentication
- `Current.actor` wiring
- explicit `recording_studio_accessible` installation for the extracted access addon and its `RecordingStudioAccessible.authorized?` authorization API
- seed/setup access grants through `RecordingStudioAccessible.grant_access`
- the required Recording Studio Accessible install/migration flow before duplication is used
- root `Workspace` recording setup
- Cards that post to the gem-provided duplicate endpoint
- Recording Studio core default layout with Flatpack components
- the resulting duplicated workspace recordings in the UI

Run it with:

```bash
cd test/dummy
bundle install
bin/rails db:setup
bin/dev
```

Default login:

- `admin@admin.com`
- `Password`

## Development

Run the main validation commands from the repository root:

```bash
bundle install
bundle exec rake test
bundle exec rubocop
```
