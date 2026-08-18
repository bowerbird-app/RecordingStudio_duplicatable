# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/bowerbird-app/RecordingStudio_duplicatable/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/bowerbird-app/RecordingStudio_duplicatable/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/bowerbird-app/RecordingStudio_duplicatable/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/bowerbird-app/RecordingStudio_duplicatable/releases/tag/v0.1.0
