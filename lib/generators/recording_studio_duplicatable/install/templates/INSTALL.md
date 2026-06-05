Recording Studio duplicatable addon install complete.

Next steps:

1. Review config/initializers/recording_studio_duplicatable.rb and set any duplication defaults you need.
2. If you use environment-specific settings, create config/recording_studio_duplicatable.yml.
3. Install and configure `recording_studio_accessible` before using duplication so
   `RecordingStudioAccessible.authorized?` can authorize duplicate requests:
   `bin/rails generate recording_studio_accessible:install`
4. Install Recording Studio Accessible migrations and apply them before using duplication:
   `bin/rails generate recording_studio_accessible:migrations && bin/rails db:migrate`
5. Run bin/rails tailwindcss:build if you use Tailwind CSS.
6. Mount routes are added at the configured mount path, including the built-in duplicate endpoint.
7. Keep Recording Studio configured with your current actor, for example `config.actor = -> { Current.actor }`.
8. Add `recording_studio_recordable` declarations to every configured Recording Studio 3 recordable.
9. Use `RecordingStudioAccessible.grant_access` for setup and seed access grants.
10. Render duplicate buttons with the mounted helper, for example:
   `recording_studio_duplicatable.duplicate_recording_path(recording_id: recording.id)`
