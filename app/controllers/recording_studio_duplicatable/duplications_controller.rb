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
                    alert: t(
                      "recording_studio.duplicatable.flashes.no_actor",
                      default: "No current actor is available to duplicate this recording."
                    )
    end

    def redirect_missing_recording
      redirect_back fallback_location: duplication_fallback_location,
                    alert: t(
                      "recording_studio.duplicatable.flashes.no_recording",
                      default: "No recording is available to duplicate."
                    )
    end

    def redirect_with_duplication_result(result)
      flash_type = result.success? ? :notice : :alert
      redirect_back fallback_location: duplication_fallback_location,
                    flash_type => duplication_result_message(result)
    end

    def duplication_result_message(result)
      if result.success?
        created_duplicate_notice(result.value)
      else
        duplication_failed_alert(result.error)
      end
    end

    def created_duplicate_notice(recording)
      # rubocop:disable Style/FormatStringToken -- I18n interpolation, not Ruby format
      t(
        "recording_studio.duplicatable.flashes.created",
        label: duplicated_recordable_label(recording),
        default: 'Created duplicate "%{label}".'
      )
      # rubocop:enable Style/FormatStringToken
    end

    def duplication_failed_alert(error)
      # rubocop:disable Style/FormatStringToken -- I18n interpolation, not Ruby format
      t(
        "recording_studio.duplicatable.flashes.failed",
        error: translate_duplication_error(error),
        default: "Duplication failed: %{error}"
      )
      # rubocop:enable Style/FormatStringToken
    end

    def translate_duplication_error(error)
      english = "Actor does not have :edit access for duplication"
      case error.to_s
      when english
        t("recording_studio.duplicatable.errors.access_denied", default: english)
      else
        error
      end
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
