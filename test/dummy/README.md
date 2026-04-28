# Dummy App

This Rails app exists to validate the Recording Studio addon template in a real host application.

## What It Covers

- Devise authentication with a seeded admin user
- `Current.actor` wiring for Recording Studio events
- Root workspace and root recording setup
- Explicit `recording_studio_accessible` installation for access behavior
- FlatPack layout integration and Tailwind source scanning
- Mounted `RecordingStudio::Engine` route behavior inside a host app
- Mounted `RecordingStudioAccessible::Engine` route behavior inside a host app

## Quick Start

```bash
bundle install
bin/rails db:setup
bin/dev
```

The dummy schema intentionally includes the access tables required by `recording_studio_accessible`, so access behavior is present because the addon is installed explicitly, not because `recording_studio` silently bundled it.

Then open the app and sign in with:

- Email: `admin@admin.com`
- Password: `Password`

## Useful Routes

- `/` - dummy app home page and template guidance
- `/recording_studio` - mounted Recording Studio engine
- `/recording_studio_accessible` - mounted Recording Studio Accessible engine
- `/users/sign_in` - Devise sign-in page
- `/up` - Rails health check

## Why This App Exists

Use this app to verify the generated addon experience before renaming the gem or copying patterns into another host app. If a layout, route, asset source, or Recording Studio initializer change breaks here, the template likely needs adjustment before reuse.
