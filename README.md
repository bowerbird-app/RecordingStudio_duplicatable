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
gem "recording_studio"
gem "recording_studio_accessible"
gem "recording_studio_duplicatable", github: "bowerbird-app/RecordingStudio_duplicatable"
```

Then run the installer if you want the initializer, YAML config, mount, and Tailwind source hints:

```bash
bundle install
bin/rails generate recording_studio_accessible:install
bin/rails generate recording_studio_accessible:migrations
bin/rails db:migrate
bin/rails generate recording_studio_duplicatable:install
```

The installer mounts the engine so host app views can use the built-in duplicate endpoint.
Install and configure `recording_studio_accessible` before using duplication so authorization is provided by Recording Studio Accessible.
If Recording Studio Accessible adds migrations for your app, make sure those migrations are installed and applied before you use duplication.

## Opting a model into duplication

Use the capability directly:

```ruby
class Workspace < ApplicationRecord
  include RecordingStudioDuplicatable::Capabilities::Duplicatable
end
```

Or configure per-type overrides:

```ruby
class Workspace < ApplicationRecord
  include RecordingStudioDuplicatable::Capabilities::Duplicatable.with(
    prefix: nil,
    suffix: " (Copy)",
    include_children: nil,
    exclude_children: nil
  )
end
```

## Configuration

Global defaults:

```ruby
RecordingStudioDuplicatable.configure do |config|
  config.duplication_prefix = nil
  config.duplication_suffix = " (Copy)"
  config.duplication_rename_attribute = nil
end
```

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
- passes optional `Current.impersonator`
- relies on the existing duplication API, which performs the standard Recording Studio Accessible-backed duplication authorization check
- redirects back with a notice or alert

Make sure your host app keeps Recording Studio configured with the current actor, for example:

```ruby
RecordingStudio.configure do |config|
  config.actor = -> { Current.actor }
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
- The actor must be authorized by Recording Studio Accessible to duplicate the target recording
- The capability must be enabled for the recordable type
- Child-copy filters apply recursively through the descendant tree
- Post-duplication callbacks and hooks run after the transaction completes

## Dummy app

The dummy app in `test/dummy/` demonstrates:

- Devise authentication
- `Current.actor` wiring
- explicit `recording_studio_accessible` installation for access models and checks
- the required Recording Studio Accessible install/migration flow before duplication is used
- root `Workspace` recording setup
- cards that post to the gem-provided duplicate endpoint
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
