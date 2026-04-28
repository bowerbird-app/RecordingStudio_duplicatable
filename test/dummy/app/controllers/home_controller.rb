class HomeController < ApplicationController
  helper_method :child_count_for, :recordable_subtitle, :recordable_title, :child_recording_link,
                :child_recording_title, :duplicate_recording_path_for

  def index
    @pages = Page.includes(:workspace, :comments).order(:created_at)
    @reports = Report.includes(:workspace, :comments).order(:created_at)
    @folders = Folder.includes(:workspace, :comments, :child_folders).where(parent_folder_id: nil).order(:created_at)
    @recordings_by_key = load_recordings_for(@pages, @reports, @folders)
  end

  def show_page
    page = Page.find_by!(slug: params[:slug])
    assign_recordable_show(page, recordable_type_label: "Page")
  end

  def show_report
    report = Report.find_by!(slug: params[:slug])
    assign_recordable_show(report, recordable_type_label: "Report")
  end

  def show_folder
    folder = Folder.find_by!(slug: params[:slug])
    assign_recordable_show(folder, recordable_type_label: "Folder")
  end

  private

  def assign_recordable_show(recordable, recordable_type_label:)
    @recordable = recordable
    @recordable_type_label = recordable_type_label
    @recording = RecordingStudio::Recording.unscoped.includes(child_recordings: :recordable).find_by(recordable: recordable)
    @child_recordings = Array(@recording&.child_recordings).sort_by(&:created_at)
    @child_folder_recordings = @child_recordings.select { |child_recording| child_recording.recordable.is_a?(Folder) }
    render :show_recordable
  end

  def load_recordings_for(*collections)
    collections.flatten.compact.group_by { |recordable| recordable.class.name }.flat_map do |recordable_type, recordables|
      RecordingStudio::Recording.unscoped
        .includes(:child_recordings)
        .where(recordable_type: recordable_type, recordable_id: recordables.map(&:id))
    end.index_by { |recording| recording_key(recording.recordable) }
  end

  def child_count_for(recordable)
    return 0 unless @recordings_by_key

    recording_for(recordable)&.child_recordings&.size.to_i
  end

  def duplicate_recording_path_for(recordable)
    recording = recording_for(recordable)
    return unless recording

    recording_studio_duplicatable.duplicate_recording_path(recording_id: recording.id)
  end

  def recordable_title(recordable)
    recordable.try(:title).presence || recordable.try(:name).presence || recordable.class.name
  end

  def recordable_subtitle(recordable)
    recordable.try(:summary).presence || recordable.try(:description).presence
  end

  def child_recording_title(child_recording)
    recordable_title(child_recording.recordable)
  end

  def child_recording_path(child_recording)
    case child_recording.recordable
    when Page
      page_path(child_recording.recordable.slug)
    when Report
      report_path(child_recording.recordable.slug)
    when Folder
      folder_path(child_recording.recordable.slug)
    end
  end

  def child_recording_link(child_recording)
    path = child_recording_path(child_recording)
    return "—" unless path

    view_context.link_to("Show", path, class: "text-primary")
  end

  def recording_key(recordable)
    [ recordable.class.name, recordable.id ]
  end

  def recording_for(recordable)
    return unless @recordings_by_key

    @recordings_by_key.fetch(recording_key(recordable), nil)
  end
end
