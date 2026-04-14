# frozen_string_literal: true

RecordingStudioDuplicatable.configure do |config|
  # Prefix applied to duplicated names/titles.
  # config.duplication_prefix = "[Copy] "

  # Suffix applied to duplicated names/titles.
  # config.duplication_suffix = " (Copy)"

  # Override rename attribute detection (:name, then :title by default).
  # config.duplication_rename_attribute = :title
end
