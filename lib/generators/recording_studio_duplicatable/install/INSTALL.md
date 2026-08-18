===============================================================================

RecordingStudioDuplicatable has been installed successfully!

The engine has been mounted at /recording_studio_duplicatable in your application.

If you use Tailwind CSS:
1. Run 'bin/rails tailwindcss:build' to rebuild your CSS with RecordingStudioDuplicatable styles

To use the engine:
1. Start your Rails server
2. Visit http://localhost:3000/recording_studio_duplicatable
3. Install Recording Studio core with `bin/rails generate recording_studio:install`
   and `bin/rails generate recording_studio:migrations`.
4. Install and configure `recording_studio_accessible` before using duplication so
   `RecordingStudioAccessible.authorized?` can authorize duplicate requests.
5. Install Recording Studio Accessible migrations and run `bin/rails db:migrate` before using duplication.
6. Render duplicate buttons with the built-in route helper, for example:
   `recording_studio_duplicatable.duplicate_recording_path(recording_id: recording.id)`
7. Make sure your host app still provides the current actor through Recording Studio,
   for example `config.actor = -> { Current.actor }`
8. Add `recording_studio_recordable` declarations to every configured Recording Studio 4 recordable.
9. Use `RecordingStudioAccessible.grant_access` for setup and seed access grants.

===============================================================================
