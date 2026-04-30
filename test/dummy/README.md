# Dummy App

This Rails app exists to validate the Recording Studio duplicatable addon in a real host application.

## What It Covers

- Devise authentication with a seeded admin user
- `Current.actor` wiring for Recording Studio events
- explicit `recording_studio_accessible` setup so duplication authorization comes from `RecordingStudioAccessible.authorized?`
- the required Recording Studio Accessible install/migration flow before duplication is used
- A seeded `Workspace` root recording with child `Page`, `Report`, `Folder`, and `Comment` recordables
- The mounted RecordingStudioDuplicatable engine and its built-in duplicate endpoint
- FlatPack layout integration and Tailwind source scanning
- A page/report/folder duplication demo that posts to the gem-provided duplicate route and shows included vs excluded child copying
- Sidebar-linked static guides for setup, approach, use, and methods

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

- `/` - seeded `Page`, `Report`, and `Folder` cards with duplicate actions that post to the mounted engine
- `/pages/:slug` - inspect a seeded page and its child recordings
- `/reports/:slug` - inspect a seeded report and its child recordings
- `/folders/:slug` - inspect a seeded folder and its nested child recordings
- `/guides/setup` - how to install Recording Studio Accessible, run its migrations, mount the engine, provide the current actor, and wire duplication through `RecordingStudioAccessible.authorized?`
- `/guides/approach` - the addon's deliberately narrow duplication approach and default behaviors
- `/guides/use` - how to use the built-in duplicate route or the optional service object
- `/guides/methods` - the built-in route, service, and recording APIs explained
- `/users/sign_in` - Devise sign-in page

## Why This App Exists

Use this app to verify the real addon integration in a host application. If authentication, layout wiring, asset sources, or the recordable duplication flow break here, the addon likely needs adjustment before release.
