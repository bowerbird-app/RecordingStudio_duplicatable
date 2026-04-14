# Dummy App

This Rails app exists to validate the Recording Studio duplicatable addon in a real host application.

## What It Covers

- Devise authentication with a seeded admin user
- `Current.actor` wiring for Recording Studio events
- Root workspace and root recording setup
- FlatPack layout integration and Tailwind source scanning
- Mounted `RecordingStudio::Engine` route behavior inside a host app
- `GemTemplate::Capabilities::Duplicatable` wired on `Workspace`
- A live "Duplicate current workspace" demo on the home page

## Quick Start

```bash
bundle install
bin/rails db:setup
bin/dev
```

Then open the app and sign in with:

- Email: `admin@admin.com`
- Password: `Password`

## Useful Routes

- `/` - dummy app home page, duplication demo, and Duplicatable capability status
- `/recording_studio` - mounted Recording Studio engine path (the bare base route redirects to `/`)
- `/users/sign_in` - Devise sign-in page
- `/up` - Rails health check

## Why This App Exists

Use this app to verify the generated addon experience before renaming the gem or copying patterns into another host app. If a layout, route, asset source, or Recording Studio initializer change breaks here, the template likely needs adjustment before reuse.

The home page includes a **Duplicatable capability** card with a real duplicate action. Use it to create a duplicate `Workspace`, confirm the configured per-type options, and inspect the resulting workspace recordings without adding any addon-specific views to the engine itself.
