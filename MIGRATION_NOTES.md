# Migration Notes

## 0.6.0 layout upgrade

Recording Studio `v6.1.0` removed `RecordingStudio::UsesDefaultLayout`, `recording_studio/action_layout`, and `recording_studio/shared/page_nav`.

1. Require `recording_studio` `>= 6.1.0` and pin tag `v6.1.0`.
2. Pin `flat_pack` to git ref `1fcbafe94f8eb118f0a22182f63f5110fcc97a56` (`0.1.319`). `v0.1.315` is the newest tag and is older than that ref.
3. Pin `view_component` to `4.19.0`.
4. If Accessible, Trashable, or Metrics still require `recording_studio` below 6, load `test/support/widen_recording_studio_requirement.rb` before Bundler evaluates gemspecs.
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
