class HomeController < ApplicationController
  def index
    @workspace = Workspace.order(:created_at).first
    @root_recording = current_workspace_root_recording
    @duplicatable_options = if defined?(RecordingStudio)
                              RecordingStudio.capability_options(:duplicatable, for_type: "Workspace") || {}
                            else
                              {}
                            end
    @workspace_recordings = workspace_recordings
    @workspace_duplicates = @workspace_recordings.reject { |recording| recording.id == @root_recording&.id }
  end

  def duplicate_workspace
    root_recording = current_workspace_root_recording
    unless root_recording
      redirect_to root_path, alert: "No workspace recording is available to duplicate."
      return
    end

    result = GemTemplate::Services::DuplicationService.call(
      recording: root_recording,
      actor: current_user
    )

    if result.success?
      redirect_to root_path, notice: %(Created duplicate "#{result.value.recordable.name}".)
    else
      redirect_to root_path, alert: "Duplication failed: #{result.error}"
    end
  end

  private

  def current_workspace_root_recording
    workspace = @workspace || Workspace.order(:created_at).first
    return unless workspace

    RecordingStudio::Recording.unscoped.find_by(
      recordable: workspace,
      parent_recording_id: nil
    )
  end

  def workspace_recordings
    RecordingStudio::Recording.unscoped
                              .where(recordable_type: "Workspace")
                              .includes(:recordable)
                              .order(created_at: :asc)
  end
end
