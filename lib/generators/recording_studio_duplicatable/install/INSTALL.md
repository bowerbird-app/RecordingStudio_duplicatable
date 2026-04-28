===============================================================================

RecordingStudioDuplicatable has been installed successfully!

The engine has been mounted at /recording_studio_duplicatable in your application.

If you use Tailwind CSS:
1. Run 'bin/rails tailwindcss:build' to rebuild your CSS with RecordingStudioDuplicatable styles

To use the engine:
1. Start your Rails server
2. Visit http://localhost:3000/recording_studio_duplicatable
3. Render duplicate buttons with the built-in route helper, for example:
   `recording_studio_duplicatable.duplicate_recording_path(recording_id: recording.id)`
4. Make sure your host app still provides the current actor through Recording Studio,
   for example `config.actor = -> { Current.actor }`

===============================================================================
