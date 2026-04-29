# frozen_string_literal: true

RecordingStudioDuplicatable.configure do |config|
  # The built-in duplication endpoint uses your Recording Studio actor resolver.
  # Install recording_studio_accessible alongside this addon so duplication
  # authorization comes from RecordingStudioAccessible.authorized?.
  # Before using duplication in a host app, run:
  #   bin/rails generate recording_studio_accessible:install
  #   bin/rails generate recording_studio_accessible:migrations
  #   bin/rails db:migrate
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
