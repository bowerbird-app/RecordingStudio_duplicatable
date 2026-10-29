# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.6.1] - 2026-10-29

### Changed
- Version `0.6.0` to `0.6.1`
- Agent and Copilot project notes use `RecordingStudioDuplicatable` instead of leftover `GemTemplate` wording
- README names Flatpack tag `v0.1.329` as the current newest tag. The dummy and development pin is still git ref `1fcbafe94f8eb118f0a22182f63f5110fcc97a56` (`FlatPack::VERSION` `0.1.319`)

### Upgrade Notes
- Bump to `0.6.1`. No migration. No behavior change.

## [0.6.0] - 2026-10-27

### Changed
- Version `0.5.0` to `0.6.0`
- Runtime dependency is now `recording_studio` `>= 6.1.0` (tested with tag `v6.1.0`)
- Development and dummy apps pin `flat_pack` git ref `1fcbafe94f8eb118f0a22182f63f5110fcc97a56` (`FlatPack::VERSION` `0.1.319`) and `view_component` `4.19.0`
- `RecordingStudioDuplicatable::Configuration` stores `layout` through `RecordingStudio::Layout.accept`. The default is `nil`
- `RecordingStudioDuplicatable::ApplicationController` calls `recording_studio_layout` with that setting. `UsesDefaultLayout` and `layout "recording_studio/default_layout"` are gone
- The engine no longer ships `HomeController`, views, or `root "home#index"`. Its only route is `POST recordings/:recording_id/duplicate`. The overview page and `recording_studio.duplicatable.home.*` copy live in the dummy app at `/engine_status`
- Dummy pages set `content_for :title` and `content_for :subtitle`. The default layout renders the single page heading. Back links use `flat_pack_page_nav`. Page actions use `register_page_nav`
- Cards use `background`, `border`, and `shadow`. The removed `style:` keyword is gone from dummy views

### Upgrade Notes
- Move the host app to Recording Studio `v6.1.0` or newer (`tag: "v6.1.0"` when the gem comes from git). Stay on `0.5.x` if you are still on Recording Studio 4.
- Set `config.layout` only when this gem's screens should use a different layout than `RecordingStudio.configuration.layout`. Leave it `nil` to keep the shared default layout.
- Replace `recording_studio_page_nav` and inline page-level `FlatPack::PageTitle::Component` calls with `content_for :title`, `content_for :subtitle`, `flat_pack_page_nav`, and `register_page_nav`.
- Remove `style:` from `FlatPack::Card::Component`. Use `border:` and `shadow:` instead.
- Load Flatpack stylesheets before Tailwind.
- Sibling gems that still require `recording_studio` below 6 need a Bundler override such as `test/support/widen_recording_studio_requirement.rb` before `bundle install` can resolve `v6.1.0`.
- Duplication behavior is unchanged. Copy writes stay inside a transaction with row locks, and authorization still goes through `RecordingStudioAccessible.authorized?`.

## [0.5.0] - 2026-10-13

### Added
- English Rails I18n keys under `recording_studio.duplicatable.*` for the engine home page, duplication controller flashes, and the known access-denied error string shown in failure flashes
- Locale regression: every `lib/**/*.rb` file must not mention `i18n.load_path` / `I18n.load_path`
- Host override coverage: test-only fixture plus always-loaded boot-order guard on the rarely shown `flashes.no_recording` key
- Render-level literal-English asserts for the engine home page and duplication flashes

### Changed
- Version `0.4.1` → `0.5.0`
- Engine home copy and duplication controller notices/alerts resolve through `t(..., default: <main English>)` (English output unchanged)
- Known access-denied service errors stay English on the Result; the controller maps that English at flash render time so hosts can translate it

### Upgrade Notes
- Bump to `0.5.0`. No migration.
- English hosts need no change. Copy `recording_studio.duplicatable.*` keys into host locale files when translating.
- Hosts override by defining the same nested keys in their own `config/locales`.
- Generator CLI text, `ArgumentError`s, hook/log messages, `MissingDependencyError`, configuration defaults such as `" (Copy)"` (written into stored titles), and icon/style tokens stay untranslated.

## [0.4.1] - 2026-09-02

Cloud Agent Builds for this gem now match Billing 0.9.13. Boot files are
tracked. A warm snapshot skips provision and still fetches skills.

### Added
- `.cursor/fetch-skills.sh`, `.cursor/install.sh`, `.cursor/start.sh`, and
  `.cursor/environment.json` for Cloud Agent boot. Install skips apt,
  ruby-build, db:prepare, and tailwind when Ruby, bundle, and Postgres are
  already usable. A skippable provision failure does not fail the Build.
  Fetch-skills always runs last. Start only brings PostgreSQL up.

### Upgrade Notes
- No host or schema changes. Rebuild the Cloud Agent environment with Draft
  off so Build loads the pack.

## [0.4.0] - 2026-08-21

### Added
- Canonical host verb `include RecordingStudio::Capabilities::Duplicatable.to(**opts)` wrapping `RecordingStudio::Capabilities.include_for(:duplicatable, **options)`

### Changed
- Runtime dependency is now RecordingStudio `~> 4.2` (tested with `4.2.0`)
- Dummy recordables enable duplication with `.to` instead of `.with`
- Dummy app uses Recording Studio core default layout with Flatpack

### Upgrade Notes
- Host apps must move to RecordingStudio `~> 4.2` (`tag: "v4.2.0"` where a git tag is used). Stay on `0.3.x` if you are still on RecordingStudio 4.0/4.1.
- Enable duplication with `include RecordingStudio::Capabilities::Duplicatable.to(**opts)`. Installing the gem still does not enable the capability.
- Parent rules stay on `recording_studio_recordable`.
- Bare `include RecordingStudioDuplicatable::Capabilities::Duplicatable` and `.with(...)` remain aliases of `.to`.

## [0.3.0] - 2026-08-18

### Changed
- Runtime dependency is now RecordingStudio `~> 4.0` (tested with `4.0.0`)
- Runtime dependency is now Recording Studio Accessible `~> 0.6` (tested with the 0.6.0 RecordingStudio 4 support branch)
- Dummy app pins FlatPack `v0.1.129` and installs the RecordingStudio 4 harden / unique-root indexes
- Dummy app configures `RecordingStudioAccessible` `access_actor_types` so seed grants succeed under Accessible 0.5+

### Upgrade Notes
- Host apps must move to RecordingStudio `~> 4.0` and Recording Studio Accessible `~> 0.6` with this gem. Stay on `0.2.x` if you are still on RecordingStudio 3 / Accessible 0.3–0.5.
- Run `bin/rails generate recording_studio:migrations` and `bin/rails db:migrate` so the 4.0 harden / unique-root indexes are installed. Resolve duplicate root recordings before the unique index is created.
- Configure `config.access_actor_types` (for example `["User"]`) before granting access. Blank allowlists reject new grants since Accessible 0.5.0.
- Follow RecordingStudio 4.0 upgrade notes for implicit recording order (use `.recent` or explicit `order:`) and append-only events.
- Prefer `config.require_actor = true` (and optionally `authorize_write` / `max_metadata_bytes`) in production hosts.

## [0.2.0] - 2026-06-05

### Changed
- Focused the repository and documentation on the Recording Studio duplicatable addon
- Updated duplication to recursively copy descendant recordings when child copying is enabled
- Removed template-only example service and placeholder configuration settings
- Updated the addon for the RecordingStudio 3 API and recordable hierarchy declarations
- Switched runtime dependencies to RecordingStudio 3 and Recording Studio Accessible 0.3.x
- Documented host app setup for RecordingStudio 3, Recording Studio Accessible, and duplicatable capabilities

### Fixed
- Delegated duplication authorization through Recording Studio Accessible
- Preserved actor and impersonator resolution through Recording Studio configuration with Current fallbacks

## [0.1.0] - 2025-12-04

### Added
- Initial release
- Rails mountable engine structure
- PostgreSQL with UUID primary keys support
- TailwindCSS v4 integration
- GitHub Codespaces devcontainer configuration
- Docker Compose setup with PostgreSQL and Redis
- Install generator for host applications
- Comprehensive README and documentation
- Basic test suite with Minitest

[Unreleased]: https://github.com/bowerbird-app/RecordingStudio_duplicatable/compare/v0.6.1...HEAD
[0.6.1]: https://github.com/bowerbird-app/RecordingStudio_duplicatable/compare/v0.6.0...v0.6.1
[0.6.0]: https://github.com/bowerbird-app/RecordingStudio_duplicatable/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/bowerbird-app/RecordingStudio_duplicatable/compare/v0.4.1...v0.5.0
[0.4.1]: https://github.com/bowerbird-app/RecordingStudio_duplicatable/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/bowerbird-app/RecordingStudio_duplicatable/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/bowerbird-app/RecordingStudio_duplicatable/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/bowerbird-app/RecordingStudio_duplicatable/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/bowerbird-app/RecordingStudio_duplicatable/releases/tag/v0.1.0
