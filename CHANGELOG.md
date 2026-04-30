# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.1] - 2026-04-30

### Changed
- Added a runtime dependency on `flat_pack ~> 0.1.33` and pinned the development and dummy bundles to the `v0.1.33` tag
- Updated the dummy app to match FlatPack's current install contract, including rich text stylesheets, importmap pins, Stimulus lazy loading, and Tailwind verification wiring
- Updated installation guidance to include the FlatPack install and verification steps required by the shipped addon UI

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

[Unreleased]: https://github.com/bowerbird-app/RecordingStudio_duplicatable/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/bowerbird-app/RecordingStudio_duplicatable/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/bowerbird-app/RecordingStudio_duplicatable/releases/tag/v0.1.0
