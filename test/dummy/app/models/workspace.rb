class Workspace < ApplicationRecord
  recording_studio_recordable label: "Workspace", root: true
  RecordingStudio.enable_capability(:accessible, on: self) if defined?(RecordingStudio)
  RecordingStudio.enable_capability(:api_access_point, on: self) if defined?(RecordingStudioApi)

  has_many :pages, dependent: :destroy
  has_many :reports, dependent: :destroy
  has_many :folders, dependent: :destroy
end
