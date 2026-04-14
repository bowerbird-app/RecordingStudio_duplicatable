class HomeController < ApplicationController
  def index
    @workspace = Workspace.first
    @root_recording = RecordingStudio::Recording.unscoped.find_by(
      recordable: @workspace,
      parent_recording_id: nil
    )
    @duplicatable_options = if defined?(RecordingStudio)
                              RecordingStudio.capability_options(:duplicatable, for_type: "Workspace") || {}
                            else
                              {}
                            end
  end
end
