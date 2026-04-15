# Dummy App

This Rails app exists to validate the Recording Studio duplicatable addon in a real host application.

## What It Covers

- Devise authentication with a seeded admin user
- `Current.actor` wiring for Recording Studio events
- A seeded `Workspace` root recording with child `Page`, `Report`, `Folder`, and `Comment` recordables
- FlatPack layout integration and Tailwind source scanning
- A page/report/folder duplication demo that shows included vs excluded child copying
- Sidebar-linked static guides for setup, use, and methods

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

- `/` - seeded `Page`, `Report`, and `Folder` cards with duplicate actions
- `/pages/:slug` - inspect a seeded page and its child recordings
- `/reports/:slug` - inspect a seeded report and its child recordings
- `/folders/:slug` - inspect a seeded folder and its nested child recordings
- `/guides/setup` - how to opt a recordable into duplication
- `/guides/use` - how to call the duplication service
- `/guides/methods` - the addon API surface explained
- `/users/sign_in` - Devise sign-in page

## Why This App Exists

Use this app to verify the real addon integration in a host application. If authentication, layout wiring, asset sources, or the recordable duplication flow break here, the addon likely needs adjustment before release.
