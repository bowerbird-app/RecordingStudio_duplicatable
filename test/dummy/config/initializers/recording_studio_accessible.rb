# frozen_string_literal: true

RecordingStudioAccessible.configure do |config|
  # Required since Accessible 0.5.0 — new grants fail closed without an allowlist.
  config.access_actor_types = [ "User" ]
end
