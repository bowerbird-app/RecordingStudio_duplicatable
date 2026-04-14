class HomeController < ApplicationController
  helper_method :duplicate_page?

  def index
    @pages = Page.includes(:workspace).order(:created_at)
  end

  def show
    @page = Page.find_by!(slug: params[:slug])
    @api_methods = duplicatable_api_methods if @page.slug == "methods"
  end

  def duplicate_page
    page = Page.find_by!(slug: params[:slug])
    recording = page_recording(page)

    unless recording
      redirect_to root_path, alert: "No page recording is available to duplicate."
      return
    end

    result = RecordingStudioDuplicatable::Services::DuplicationService.call(
      recording: recording,
      actor: current_user
    )

    if result.success?
      redirect_to root_path, notice: %(Created duplicate "#{result.value.recordable.title}".)
    else
      redirect_to root_path, alert: "Duplication failed: #{result.error}"
    end
  end

  private

  def page_recording(page)
    RecordingStudio::Recording.unscoped.find_by(recordable: page)
  end

  def duplicate_page?(page)
    page.slug.match?(/-\d+\z/) || page.title.include?("(Copy)")
  end

  def duplicatable_api_methods
    [
      {
        name: "include RecordingStudioDuplicatable::Capabilities::Duplicatable",
        description: "Turns on the capability for a recordable type using the global defaults."
      },
      {
        name: ".with(prefix:, suffix:, include_children:, exclude_children:)",
        description: "Enables the capability with per-type duplication settings."
      },
      {
        name: "recording.duplicate_in_place!(actor:, ...)",
        description: "Duplicates a Recording Studio recording directly when you already have the recording object."
      },
      {
        name: "RecordingStudioDuplicatable::Services::DuplicationService.call(recording:, actor:, ...)",
        description: "Wraps duplication in the addon result object for controller-friendly success and error handling."
      }
    ]
  end
end
