# GemTemplate

Recording Studio addon that provides a simple, opt-in duplicatable capability for recordables.

## What's Included

- **RecordingStudio** gem installed and configured
- **Devise** authentication with a pre-seeded admin user
- **Workspace** root recording set up following RecordingStudio's Quick Start pattern
- **FlatPack** UI component library for all views
- **Dummy app** (`test/dummy/`) with a working login screen, FlatPack default sidebar layout, and a live duplication demo

## Quick Start

### GitHub Codespaces (Recommended)

1. Click **Code** → **Codespaces** → **Create codespace**
2. Wait for setup to complete
3. Run:
   ```bash
   cd test/dummy
   bin/rails db:setup
   bin/dev
   ```
4. Open port 3000 — you'll see the login screen

The dummy app already includes FlatPack generator output (`flat_pack:install` and default sidebar layout scaffold) so authenticated pages render with the FlatPack sidebar shell by default.

### Login Credentials

| Field    | Value             |
|----------|-------------------|
| Email    | admin@admin.com   |
| Password | Password          |

The login form is prefilled with these credentials for fast access.

## Architecture

### Root Recording Pattern

This template follows RecordingStudio's root recording pattern:

- **Workspace** is the top-level recordable
- A root `RecordingStudio::Recording` wraps the Workspace
- The admin user has root-level admin access via `RecordingStudio::Access`
- `Current.actor` is set from `current_user` (Devise) in `ApplicationController`

### Extending RecordingStudio

To add new recordable types:

1. Create your model (e.g., `Page`, `Comment`)
2. Register it in `config/initializers/recording_studio.rb`:
   ```ruby
   RecordingStudio.configure do |config|
     config.recordable_types = ["Workspace", "YourNewType"]
   end
   ```
3. Leave optional behavior off by default, then opt into capabilities on the specific recordable models that need them:
   ```ruby
   class YourNewType < ApplicationRecord
     include RecordingStudio::Capabilities::Movable.to("Workspace")
     include RecordingStudio::Capabilities::Copyable.to("Workspace")
   end
   ```
4. If you want per-device root persistence, wire it explicitly in your controller layer:
   ```ruby
   class ApplicationController < ActionController::Base
     include RecordingStudio::Concerns::DeviceSessionConcern
   end
   ```
5. Create recordings under the root:
   ```ruby
   root_recording.record(YourNewType) do |record|
     record.title = "Example"
   end
   ```

### Capabilities

This template uses the current RecordingStudio approach: built-in capabilities are off by default and are enabled per recordable type by including the relevant module on the model.

- `movable`
- `copyable`
- `duplicatable` ← provided by this engine (see below)

Device session persistence is separate from capabilities. It is enabled only when you include `RecordingStudio::Concerns::DeviceSessionConcern` in your controller layer.

Enable behavior intentionally where it belongs:

```ruby
class RecordingStudioPage < ApplicationRecord
  include RecordingStudio::Capabilities::Movable.to("Workspace")
  include RecordingStudio::Capabilities::Copyable.to("Workspace")
end

class ApplicationController < ActionController::Base
  include RecordingStudio::Concerns::DeviceSessionConcern
end
```

---

## RecordingStudio Duplicatable Capability

`GemTemplate::Capabilities::Duplicatable` adds in-place duplication to any RecordingStudio recordable model. When a recording is duplicated, its underlying recordable is copied, optionally renamed, and a new `"duplicated"` recording is created under the same parent.

### What It Does

- Duplicates the recording's recordable object in-place under the same parent recording
- Optionally prepends/appends a prefix/suffix to the duplicate's `name` or `title` attribute
- Optionally copies child recordings of selected (or all except excluded) types
- Fires an `:after_duplicate` hook so host apps can react after the duplication transaction commits
- Raises `RecordingStudio::AccessDenied` if the actor lacks `:edit` access
- Raises `RecordingStudio::CapabilityDisabled` if the type hasn't enabled the capability
- All write work is wrapped in a database transaction with row-level locking

### How to Install

**1. Add the gem** (it's already in the engine if you're using this template):

```ruby
# Gemfile (host app)
gem "gem_template", github: "your-org/gem_template"
```

**2. Include the capability on your model:**

```ruby
# Direct include — uses global GemTemplate.configuration defaults
class Page < ApplicationRecord
  include GemTemplate::Capabilities::Duplicatable
end

# Factory method — sets per-type options that override global config
class Page < ApplicationRecord
  include GemTemplate::Capabilities::Duplicatable.with(
    prefix:           nil,
    suffix:           " (Copy)",
    include_children: nil,       # nil = don't copy children
    exclude_children: nil
  )
end
```

### Configuration Options

Global defaults can be set in an initializer:

```ruby
GemTemplate.configure do |config|
  config.duplication_prefix           = nil        # default: nil
  config.duplication_suffix           = " (Copy)"  # default: " (Copy)"
  config.duplication_rename_attribute = nil        # nil = auto-detect :name then :title
end
```

Per-type options (set via `.with(...)`) override global config.

| Option | Type | Default | Description |
|---|---|---|---|
| `prefix` | `String, nil` | `nil` | Prepended to the duplicate's name/title |
| `suffix` | `String, nil` | `" (Copy)"` | Appended to the duplicate's name/title |
| `include_children` | `Array<String,Class>, nil` | `nil` | Only copy children of these types |
| `exclude_children` | `Array<String,Class>, nil` | `nil` | Copy all children except these types |
| `duplication_rename_attribute` | `Symbol, nil` | `nil` | Override attribute detection (`:name`/`:title`) |

### Usage Examples

**Direct method call on a recording:**

```ruby
new_recording = recording.duplicate_in_place!(
  actor: current_user
)
```

**With rename and child options:**

```ruby
new_recording = recording.duplicate_in_place!(
  actor:            current_user,
  prefix:           "[COPY] ",
  suffix:           nil,
  include_children: ["Section", "Attachment"]
)
```

**Via DuplicationService (recommended for controllers):**

```ruby
result = GemTemplate::Services::DuplicationService.call(
  recording: recording,
  actor:     current_user
)

result.on_success { |new_rec| redirect_to new_rec }
result.on_failure { |msg|     render_error(msg) }
```

**With a post-duplication callback:**

```ruby
result = GemTemplate::Services::DuplicationService.call(
  recording:      recording,
  actor:          current_user,
  after_duplicate: ->(new_rec) { SearchIndex.enqueue(new_rec) }
)
```

### Post-Duplication Hooks

Register an `:after_duplicate` hook in an initializer to react to every duplication after commit:

```ruby
GemTemplate.configure do |config|
  config.hooks.on(:after_duplicate) do |new_recording|
    Rails.logger.info "Duplicated recording #{new_recording.id}"
    # Notify, reindex, sync external services, etc.
  end
end
```

---

### FlatPack UI Components

All views use FlatPack ViewComponents. Available components include:

- `FlatPack::Button::Component` — Buttons (`:primary`, `:secondary`, `:ghost`)
- `FlatPack::Card::Component` — Cards (`:default`, `:elevated`, `:outlined`)
- `FlatPack::Alert::Component` — Alerts (`:success`, `:error`, `:warning`, `:info`)
- `FlatPack::Badge::Component` — Status badges
- `FlatPack::Table::Component` — Data tables
- `FlatPack::TextInput::Component`, `EmailInput`, `PasswordInput` — Form inputs
- `FlatPack::Breadcrumb::Component` — Navigation breadcrumbs
- `FlatPack::Navbar::Component` — Navigation sidebar

See the [FlatPack README](https://github.com/bowerbird-app/flatpack) for full documentation.

## Tech Stack

| Component       | Version |
|-----------------|---------|
| Ruby            | 3.2+    |
| Rails           | 8.1+    |
| PostgreSQL      | 16      |
| TailwindCSS     | 4       |
| RecordingStudio | v0.1.0-alpha (pinned in `test/dummy/Gemfile`) |
| FlatPack        | GitHub source (`bowerbird-app/flatpack`) |
| Devise          | latest  |

## Documentation

The original gem template documentation is preserved in `docs/gem_template/` as architectural reference material. Use it as background on the engine conventions; the README and dummy app are the source of truth for the Recording Studio addon workflow.
