# GemTemplate

Internal template for building Rails engine addons on top of RecordingStudio.

## What's Included

- **RecordingStudio** gem installed and configured
- **RecordingStudio Accessible** installed explicitly when the dummy app needs access control behavior
- **Devise** authentication with a pre-seeded admin user
- **Workspace** root recording set up following RecordingStudio's Quick Start pattern
- **FlatPack** UI component library for all views
- **Dummy app** (`test/dummy/`) with a working login screen and FlatPack default sidebar layout for authenticated pages

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
- The admin user has root-level admin access via `RecordingStudio::Access`, provided explicitly by `recording_studio_accessible`
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

Device session persistence is separate from capabilities. It is enabled only when you include `RecordingStudio::Concerns::DeviceSessionConcern` in your controller layer.

Access control is also separate. If your host app needs `RecordingStudio::Access`, `RecordingStudio::AccessBoundary`, or the mounted access-management UI, install `recording_studio_accessible` explicitly:

```ruby
gem "recording_studio"
gem "recording_studio_accessible"
```

Then install its configuration and migrations intentionally instead of assuming core RecordingStudio provides them:

```bash
bin/rails generate recording_studio_accessible:install
bin/rails generate recording_studio_accessible:migrations
bin/rails db:migrate
```

Then mount the addon and opt recordables in where direct access placements should be allowed:

```ruby
mount RecordingStudioAccessible::Engine, at: "/recording_studio_accessible"

class Workspace < ApplicationRecord
  include RecordingStudioAccessible::AllowsAccessibleChildren

  recording_studio_accessible_children :access, :boundary
end
```

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
| Ruby            | 3.3+    |
| Rails           | 8.1+    |
| PostgreSQL      | 16      |
| TailwindCSS     | 4       |
| RecordingStudio | v0.1.0-alpha (pinned in `test/dummy/Gemfile`) |
| RecordingStudio Accessible | GitHub source (`bowerbird-app/RecordingStudio_accessible`) |
| FlatPack        | GitHub source (`bowerbird-app/flatpack`) |
| Devise          | latest  |

## Documentation

The original gem template documentation is preserved in `docs/gem_template/` as architectural reference material. Use it as background on the engine conventions; the README and dummy app are the source of truth for the Recording Studio addon workflow.
