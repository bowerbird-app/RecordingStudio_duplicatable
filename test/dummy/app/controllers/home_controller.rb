class HomeController < ApplicationController
  def index
    @pages = Page.includes(:workspace, :comments).order(:created_at)
    @reports = Report.includes(:workspace, :comments).order(:created_at)
  end

  def show_page
    page = Page.includes(:comments).find_by!(slug: params[:slug])
    assign_recordable_show(page, recordable_type_label: "Page")
  end

  def show_report
    report = Report.includes(:comments).find_by!(slug: params[:slug])
    assign_recordable_show(report, recordable_type_label: "Report")
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

  def assign_recordable_show(recordable, recordable_type_label:)
    @recordable = recordable
    @recordable_type_label = recordable_type_label
    @child_recordables = recordable.comments.order(:created_at)
    render :show_recordable
  end
end
