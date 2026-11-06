# frozen_string_literal: true

RecordingStudio.configure do |config|
  # Registered delegated_type recordables (strings or classes)
  config.recordable_types = [ "Workspace", "Page", "Report", "Folder", "Comment" ]

  # Actor resolver for events when no actor is explicitly supplied
  config.actor = -> { Current.actor }
  config.impersonator = -> { Current.impersonator }

  # Emit ActiveSupport::Notifications events
  config.event_notifications_enabled = true

  # Idempotency behavior for log_event!
  config.idempotency_mode = :return_existing # or :raise

  # Require each configured recordable to declare its root/parent rules.
  config.require_recordable_declarations = true

  # Recordable duplication strategy for revisions
  config.recordable_dup_strategy = :dup

  # RecordingStudio 4 production write hardening (enabled for the demo too).
  config.require_actor = true if config.respond_to?(:require_actor=)
  config.max_metadata_bytes = 16_384 if config.respond_to?(:max_metadata_bytes=)
  config.app_name = "Duplicatable Demo" if config.respond_to?(:app_name=)

  # Hosts must set authorize_write before Recording Studio core 6.5.0.
  # Writes fail closed: missing authorize_write raises AuthorizationError;
  # missing actor raises ActorRequired. `actor.present?` is not a write policy.
  config.authorize_write = lambda { |actor:, root_recording:, recordable:, **|
    next false unless actor.is_a?(User) && actor.persisted?
    next false unless root_recording

    if defined?(RecordingStudio::Access) && recordable.is_a?(RecordingStudio::Access)
      next true if recordable.actor == actor

      RecordingStudioAccessible.authorized?(
        actor: actor,
        recording: root_recording,
        role: :admin
      )
    else
      RecordingStudioAccessible.authorized?(
        actor: actor,
        recording: root_recording,
        role: :edit
      )
    end
  }

  # Built-in capabilities remain disabled until you opt a recordable type into
  # them with include RecordingStudio::Capabilities::Duplicatable.to(**opts).
end
