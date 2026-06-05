# RecordingStudio 3 Upgrade Summary

## Current scope

This branch updates RecordingStudio Duplicatable for the RecordingStudio 3 API and the extracted Recording Studio Accessible addon.

## Dependency state

- `recording_studio` is locked to revision `a2201ac47a6938472a64d17679256dbd7e0247ba`.
- `recording_studio_accessible` is locked to tag `0.3.1` and declared as a runtime dependency with `~> 0.3.1`.
- The root gem lockfile resolves Rails `8.1.1` and minitest `5.26.2`.
- The dummy app lockfile resolves Rails `8.1.3` and minitest `6.0.5`.

## Implementation notes

- Duplication authorization delegates to `RecordingStudioAccessible.authorized?`.
- Recordables declare RecordingStudio 3 hierarchy metadata with `recording_studio_recordable`.
- Recordables that should receive direct access grants opt into Recording Studio Accessible with `RecordingStudio.enable_capability(:accessible, on: self)`.
- Duplication creates a duplicated recordable and a new RecordingStudio recording for that duplicate.
- The built-in controller resolves actor and impersonator through Recording Studio configuration, with `Current` fallbacks.

## Validation

Run these commands before merging:

```bash
bundle exec rubocop
bundle exec rake app:test
```
