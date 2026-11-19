# Migration Notes

## 1.1.0 copy rules

`RecordingStudioDuplicatable.register_copy_rule(type, rule)` takes `:copy`, `:skip`, or a callable. `copy_rules:` on `Duplicatable.to`, `duplicate_in_place!`, and `DuplicationService.call` overrides the registry for that duplication. Per-call entries win over the type option, which wins over the registry.

A callable is `->(source_recordable:, source_recording:, copy:, context:) { copy }`. `context` has `actor`, `root_recording`, and `parent_recording`. Return `nil` or the copy and Duplicatable calls `save!`. Return an already persisted recordable when the rule saves it.

Children stay uncopied unless `include_children` or `exclude_children` is set. Child class names `Access`, `AccessBoundary`, `AccessConstraint`, `AccessRequest`, `AccessRule`, `Grant`, and names ending in `Token` or `Secret` are never copied. `:edit` authorization is unchanged for every recording that is copied.

`:skip` does not cancel the recording you passed to `duplicate_in_place!`. A callable for that type still runs. The copy still uses Recording Studio `duplicate_recordable`.

There is no database migration.

## 1.0.0 service base and hooks

`DuplicationService` inherits `RecordingStudio::Services::BaseService`. `.call` still returns `success?`, `failure?`, `value`, `error`, `errors`, `on_success`, `on_failure`, and `value!`.

Delete `RecordingStudioDuplicatable::Hooks`, `RecordingStudioDuplicatable::Services::BaseService`, and `RecordingStudioDuplicatable.configuration.hooks`. Register `:after_duplicate` with `RecordingStudio.configuration.hooks.on(:after_duplicate)`. The per-call `after_duplicate:` proc is unchanged. `before_service`, `after_service`, and `around_service` on `RecordingStudio.configuration.hooks` now see `DuplicationService`.

There is no database migration.

## Recording Studio 7

Hosts pin `recording_studio` tag `v7.8.0` (`~> 7.8`, gemspec `>= 7.0`, `< 8.0`) and `recording_studio_accessible` tag `v0.56.0` (`~> 0.56`, gemspec `>= 0.44.0`, `< 1.0`). Trashable `v1.2.3` (`~> 1.2`) and Metrics `v0.10.0` (`~> 0.10`) are the pins that resolve with those releases. FlatPack is tag `v0.2.0` (`~> 0.2`). Hosts on FlatPack 0.1.x still resolve. Hosts moving to 0.2 remove the manual `flat_pack/heroicons` importmap pin and any `flat-pack--icon` controller registration.
Hosts MUST run the Recording Studio 7.4, 7.5, and 7.7 migrations (`add_recording_studio_recordings_root_type_creation_index`, `enforce_recording_studio_recording_root_invariant`, and `replace_recording_studio_recordings_root_index`). The dummy app does not copy those migrations.

`RecordingStudio.root_recording_for` only finds a root. Seeds and setup create one with `RecordingStudio.create_root_recording!(recordable, actor:)`. `config.authorize_write` must allow a persisted user when `root_recording` is nil. Do not set `allow_unauthorized_writes`.

Copy Recording Studio migration `add_root_recording_id_to_recording_studio_events` and migrate before writing events. `recording_studio_events.root_recording_id` is required.

## 0.6.0 layout upgrade

Recording Studio `v6.1.0` removed `RecordingStudio::UsesDefaultLayout`, `recording_studio/action_layout`, and `recording_studio/shared/page_nav`.

1. Require `recording_studio` `>= 6.1.0` and pin the host Gemfile to tag `v6.5.0`.
2. Pin `flat_pack` to git ref `1fcbafe94f8eb118f0a22182f63f5110fcc97a56` (`0.1.319`). `v0.1.315` is the newest tag and is older than that ref.
3. Pin `view_component` to `4.19.0`.
4. Use sibling gems that already declare Recording Studio 6 (`recording_studio_layout`). Do not widen gemspecs or fake `UsesDefaultLayout`.
5. Set `config.layout` on `RecordingStudioDuplicatable::Configuration`. `nil` falls through to `RecordingStudio.configuration.layout`, then `"recording_studio/default_layout"`.
6. Call `recording_studio_layout { RecordingStudioDuplicatable.configuration.layout }` on `RecordingStudioDuplicatable::ApplicationController`. `DuplicationsController` inherits it. Do not hard-code `layout "recording_studio/default_layout"`. The engine ships no views and no home controller.
7. In the host app, move page headings to `content_for :title` and `content_for :subtitle`. Mark those strings `html_safe`. The default layout calls `to_s` on the slots, and an already escaped string is escaped again. Use `flat_pack_page_nav` for back and close, and `register_page_nav` for page actions. The dummy overview lives at `/engine_status`.
8. Run `bundle exec rake recording_studio:check_layouts` from the dummy app.

Duplication invariants stay the same. Writes stay in a transaction, rows stay locked, and `RecordingStudioAccessible.authorized?` still runs.

## Private gems to public gems

## Changes Made

1. ✅ Removed repository access entries from `.devcontainer/devcontainer.json`
2. ✅ Updated documentation in `CODESPACES.md` and `PRIVATE_GEMS.md`
3. ✅ Updated copilot instructions to reference local docs
4. ✅ Replaced `makeup_artist` with `flat_pack` in `test/dummy/Gemfile`

## Next Steps (Requires Ruby 3.3.0+)

The following steps need to be completed in an environment with Ruby 3.3.0 or higher:

1. **Update Gemfile.lock**: Run `bundle install` in the test/dummy directory to update the lockfile
   ```bash
   cd test/dummy
   bundle install
   ```

2. **Run FlatPack installer**: After bundle install, run the FlatPack installation generator
   ```bash
   cd test/dummy
   rails generate flat_pack:install
   ```

3. **Update views**: Replace any `makeup_artist` component references with `flat_pack` components
   - Search for: `MakeupArtist::`, `makeup_artist/`
   - Replace with equivalent FlatPack components

4. **Test the application**: Start the dummy app and verify all UI components work
   ```bash
   cd test/dummy
   bin/dev
   ```

5. **Run tests**: Execute the test suite
   ```bash
   bundle exec rake test
   ```

## Component Migration Guide

FlatPack is the successor to MakeupArtist with similar components:

- Both use ViewComponent architecture
- Both integrate with Tailwind CSS
- Component names and APIs may differ slightly

See: https://github.com/bowerbird-app/flatpack for component documentation
