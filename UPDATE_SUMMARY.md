# RecordingStudio 4 Upgrade Summary

## Current scope

This branch updates RecordingStudio Duplicatable for RecordingStudio 4 and Recording Studio Accessible 0.6.

## Dependency state

- `recording_studio` is pinned to tag `v4.0.0` and declared as a runtime dependency with `~> 4.0`.
- `recording_studio_accessible` is pinned to the RecordingStudio 4 support commit (`fd29789…`, version `0.6.0`) until `v0.6.0` is tagged, and declared as a runtime dependency with `~> 0.6`.
- The dummy app pins FlatPack `v0.1.129`.
- Engine and dummy lockfiles should resolve Rails `8.1.x` with `minitest-mock` for Minitest 6 `Object#stub` helpers.

## Implementation notes

- Duplication authorization still delegates to `RecordingStudioAccessible.authorized?` (no API change required for Accessible 0.6).
- Recordables declare hierarchy metadata with `recording_studio_recordable`.
- Recordables that should receive direct access grants opt into Recording Studio Accessible with `RecordingStudio.enable_capability(:accessible, on: self)`.
- Dummy app configures `access_actor_types = ["User"]` so seed `grant_access` calls succeed.
- Dummy app installs the RecordingStudio 4 harden migration for unique root recordings and composite indexes.
- Dummy RecordingStudio initializer enables `require_actor` and `max_metadata_bytes` for write hardening.

## Validation

Run these commands before merging:

```bash
bundle exec rubocop
bundle exec rake app:test
```

After Accessible `v0.6.0` is tagged, switch both Gemfiles from the commit `ref` to `tag: "v0.6.0"`.
