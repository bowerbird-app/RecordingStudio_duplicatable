class HomeController < ApplicationController
  helper_method :duplicate_recordable?

  def index
    @pages = Page.includes(:workspace, :comments).order(:created_at)
    @reports = Report.includes(:workspace, :comments).order(:created_at)
  end

  def duplicate_page
    page = Page.find_by!(slug: params[:slug])
    duplicate_recordable(page, success_key: :title)
  end

  def duplicate_report
    report = Report.find_by!(slug: params[:slug])
    duplicate_recordable(report, success_key: :title)
  end

  private

  def duplicate_recordable(recordable, success_key:)
    recording = RecordingStudio::Recording.unscoped.find_by(recordable: recordable)

    unless recording
      redirect_to root_path, alert: "No recording is available to duplicate."
      return
    end

    result = RecordingStudioDuplicatable::Services::DuplicationService.call(
      recording: recording,
      actor: current_user
    )

    if result.success?
      redirect_to root_path, notice: %(Created duplicate "#{result.value.recordable.public_send(success_key)}".)
    else
      redirect_to root_path, alert: "Duplication failed: #{result.error}"
    end
  end

  def duplicate_recordable?(recordable)
    recordable.title.include?("(Copy)") || recordable.slug.match?(/-\d+\z/)
  end
end
