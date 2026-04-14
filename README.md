# RecordingStudio Duplicatable

`RecordingStudio Duplicatable` is a Rails engine addon that adds a simple, opt-in duplication capability to Recording Studio recordables.

## What it does

- Registers a `:duplicatable` capability with Recording Studio
- Lets recordable models opt in explicitly
- Duplicates a recording in place under the same parent
- Renames the duplicate with configurable prefix/suffix rules
- Recursively duplicates descendant recordings when child copying is enabled
- Preserves Recording Studio access checks and parent/root recording relationships
- Exposes a small controller-friendly `DuplicationService`

## Installation

Add the gem from this repository to your host app:

```ruby
gem "recording_studio_duplicatable", github: "bowerbird-app/RecordingStudio_duplicatable"
```

Then run the installer if you want the initializer, YAML config, mount, and Tailwind source hints:

```bash
bin/rails generate recording_studio_duplicatable:install
```

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

Duplicate from a recording:

```ruby
new_recording = recording.duplicate_in_place!(
  actor: current_user
)
```

Or use the service object:

```ruby
result = RecordingStudioDuplicatable::Services::DuplicationService.call(
  recording: recording,
  actor: current_user
)
```

## Behavior notes

- Duplication is wrapped in a transaction with row locking
- The actor must have Recording Studio `:edit` access
- The capability must be enabled for the recordable type
- Child-copy filters apply recursively through the descendant tree
- Post-duplication callbacks and hooks run after the transaction completes

## Dummy app

The dummy app in `test/dummy/` demonstrates:

- Devise authentication
- `Current.actor` wiring
- root `Workspace` recording setup
- a live “Duplicate current workspace” action
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
