# frozen_string_literal: true

module RecordingStudioDuplicatable
  class DuplicationsController < ApplicationController
    def create
      actor = current_duplication_actor
      return redirect_missing_actor unless actor

      recording = find_recording
      return redirect_missing_recording unless recording

      result = RecordingStudioDuplicatable::Services::DuplicationService.call(
        recording: recording,
        actor: actor,
        impersonator: current_duplication_impersonator
      )

      redirect_with_duplication_result(result)
    end

    private

    def redirect_missing_actor
      redirect_back fallback_location: duplication_fallback_location,
                    alert: "No current actor is available to duplicate this recording."
    end

    def redirect_missing_recording
      redirect_back fallback_location: duplication_fallback_location,
                    alert: "No recording is available to duplicate."
    end

    def redirect_with_duplication_result(result)
      flash_type = result.success? ? :notice : :alert
      message = if result.success?
                  %(Created duplicate "#{duplicated_recordable_label(result.value)}".)
                else
                  "Duplication failed: #{result.error}"
                end

      redirect_back fallback_location: duplication_fallback_location, flash_type => message
    end

    def find_recording
      return unless defined?(RecordingStudio::Recording)

      RecordingStudio::Recording.unscoped.find_by(id: params[:recording_id])
    end

    def duplicated_recordable_label(recording)
      recordable = recording.try(:recordable)

      recordable.try(:title).presence || recordable.try(:name).presence || recordable.class.name
    end

    def duplication_fallback_location
      return main_app.root_path if main_app.respond_to?(:root_path)

      "/"
    rescue StandardError
      "/"
    end
  end
end
