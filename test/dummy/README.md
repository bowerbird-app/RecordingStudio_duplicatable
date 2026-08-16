# Dummy App

This Rails app exists to validate the Recording Studio duplicatable addon in a real host application.

## What It Covers

- Devise authentication with a seeded admin user
- `Current.actor` wiring for Recording Studio events
- explicit `recording_studio_accessible` setup so duplication authorization comes from `RecordingStudioAccessible.authorized?`
- the required Recording Studio Accessible install/migration flow before duplication is used
- Recording Studio 3 `recording_studio_recordable` declarations and `RecordingStudioAccessible.grant_access` seed grants
- A seeded `Workspace` root recording with child `Page`, `Report`, `Folder`, and `Comment` recordables
- The mounted RecordingStudioDuplicatable engine and its built-in duplicate endpoint
- FlatPack layout integration with the Rounded theme and Tailwind-generated utility layer
- A page/report/folder duplication demo that posts to the gem-provided duplicate route and shows included vs excluded child copying
- Sidebar-linked static guides for setup, approach, use, JSON API, and methods

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
- `/guides/api` - how to expose in-place duplication through Recording Studio API
- `/guides/methods` - the built-in route, service, recording, and optional JSON APIs explained
- `/users/sign_in` - Devise sign-in page

## Why This App Exists

Use this app to verify the real addon integration in a host application. If authentication, layout wiring, Tailwind compilation, theme setup, or the recordable duplication flow break here, the addon likely needs adjustment before release.
