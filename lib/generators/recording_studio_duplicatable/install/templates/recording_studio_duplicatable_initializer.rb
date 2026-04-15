# frozen_string_literal: true

RecordingStudioDuplicatable.configure do |config|
  # The built-in duplication endpoint uses your Recording Studio actor resolver.
  # In the host app, keep Recording Studio configured with something like:
  #   config.actor = -> { Current.actor }
  # and mount the engine so views can call:
  #   recording_studio_duplicatable.duplicate_recording_path(recording_id: recording.id)
  #
  # Prefix applied to duplicated names/titles.
  # config.duplication_prefix = "[Copy] "

  # Suffix applied to duplicated names/titles.
  # config.duplication_suffix = " (Copy)"

  # Override rename attribute detection (:name, then :title by default).
  # config.duplication_rename_attribute = :title
end
