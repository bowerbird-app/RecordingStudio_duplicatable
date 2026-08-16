Recording Studio duplicatable addon install complete.

Next steps:

1. Review config/initializers/recording_studio_duplicatable.rb and set any duplication defaults you need.
2. If you use environment-specific settings, create config/recording_studio_duplicatable.yml.
3. Install Recording Studio core before using duplication:
   `bin/rails generate recording_studio:install && bin/rails generate recording_studio:migrations`
4. Install and configure `recording_studio_accessible` before using duplication so
   `RecordingStudioAccessible.authorized?` can authorize duplicate requests:
   `bin/rails generate recording_studio_accessible:install`
5. Install Recording Studio Accessible migrations and apply them before using duplication:
   `bin/rails generate recording_studio_accessible:migrations && bin/rails db:migrate`
6. Run bin/rails tailwindcss:build if you use Tailwind CSS.
7. Mount routes are added at the configured mount path, including the built-in duplicate endpoint.
8. Keep Recording Studio configured with your current actor, for example `config.actor = -> { Current.actor }`.
9. Add `recording_studio_recordable` declarations to every configured Recording Studio 3 recordable.
10. Use `RecordingStudioAccessible.grant_access` for setup and seed access grants.
11. Render duplicate buttons with the mounted helper, for example:
   `recording_studio_duplicatable.duplicate_recording_path(recording_id: recording.id)`
12. Optional: install `recording_studio_api` in the host app if you want the JSON
   `duplicate` member action. Allowlist it per type; this gem does not require the API engine.
