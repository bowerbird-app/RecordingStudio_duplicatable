Recording Studio duplicatable addon install complete.

Next steps:

1. Review config/initializers/recording_studio_duplicatable.rb and set any duplication defaults you need.
2. If you use environment-specific settings, create config/recording_studio_duplicatable.yml.
3. Run bin/rails tailwindcss:build if you use Tailwind CSS.
4. Mount routes are added at the configured mount path, including the built-in duplicate endpoint.
5. Keep Recording Studio configured with your current actor, for example `config.actor = -> { Current.actor }`.
6. Render duplicate buttons with the mounted helper, for example:
   `recording_studio_duplicatable.duplicate_recording_path(recording_id: recording.id)`
