# RecordingStudio Accessible 0.11 Upgrade Summary

## Current scope

This branch updates the test app and dependency pin for Recording Studio Accessible 0.11. Gem `lib/` and `app/` are unchanged.

## Dependency state

- `recording_studio` stays on tag `v4.2.2` with runtime dependency `~> 4.2`.
- `recording_studio_accessible` is pinned to tag `v0.11.1` and declared as a runtime dependency with `~> 0.11`.
- The dummy app pins FlatPack `v0.1.129`.
- Engine and dummy lockfiles should resolve Rails `8.1.x` with `minitest-mock` for Minitest 6 `Object#stub` helpers.

## Implementation notes

- Duplication authorization still delegates to `RecordingStudioAccessible.authorized?`.
- Recordables declare hierarchy metadata with `recording_studio_recordable`.
- Recordables that should receive direct access grants opt into Recording Studio Accessible with `RecordingStudio.enable_capability(:accessible, on: self)`.
- Dummy app configures `access_actor_types = ["User"]` so seed grants succeed.
- Dummy app installs Accessible 0.8–0.11 migrations (dependent grants, invitations, string roles) plus the RecordingStudio 4 harden indexes.
- Dummy seeds bootstrap the first owner with `RecordingStudioAccessible.bootstrap_owner_access!`.
- Dummy RecordingStudio initializer enables `require_actor` and `max_metadata_bytes` for write hardening.

## Validation

Run these commands before merging:

```bash
bundle exec rubocop
bundle exec rake app:test
```
