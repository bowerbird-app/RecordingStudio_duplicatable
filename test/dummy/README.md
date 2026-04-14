# Dummy App

This Rails app exists to validate the Recording Studio duplicatable addon in a real host application.

## What It Covers

- Devise authentication with a seeded admin user
- `Current.actor` wiring for Recording Studio events
- A seeded `Workspace` root recording with child `Page` recordables
- FlatPack layout integration and Tailwind source scanning
- A simple page-card duplication demo on the home page
- Sidebar-linked setup, use, and methods guides for the addon

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

- `/` - seeded `Page` cards with a real duplicate action
- `/pages/setup` - how to opt a recordable into duplication
- `/pages/use` - how to call the duplication service
- `/pages/methods` - the addon API surface explained
- `/users/sign_in` - Devise sign-in page

## Why This App Exists

Use this app to verify the real addon integration in a host application. If authentication, layout wiring, asset sources, or the page duplication flow break here, the addon likely needs adjustment before release.
