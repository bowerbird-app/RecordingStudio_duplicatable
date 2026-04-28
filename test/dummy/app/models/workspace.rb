class Workspace < ApplicationRecord
  include RecordingStudioAccessible::AllowsAccessibleChildren

  recording_studio_accessible_children :access, :boundary
end
