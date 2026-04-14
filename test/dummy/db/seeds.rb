# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

PAGE_DEFINITIONS = [
  {
    slug: "setup",
    title: "Setup",
    summary: "Add the capability to a recordable and choose your default duplication options.",
    body: <<~TEXT,
      Include the duplicatable capability in the recordable you want to copy in place.

      For this dummy app, Page is the focused recordable type. The addon turns on the capability for that type and stores any per-type options with Recording Studio.

      Reach for the capability module when you want the model itself to opt into duplication.
    TEXT
    code_sample: <<~RUBY
      class Page < ApplicationRecord
        include RecordingStudioDuplicatable::Capabilities::Duplicatable.with(
          prefix: nil,
          suffix: " (Copy)",
          include_children: nil,
          exclude_children: nil
        )
      end
    RUBY
  },
  {
    slug: "use",
    title: "Use",
    summary: "Call the service with a page recording and the current actor to create a duplicate.",
    body: <<~TEXT,
      Duplicate from a controller or service once you have the Recording Studio recording for the recordable you want to copy.

      The dummy app keeps a recording for each seeded Page, then sends that recording to the duplication service when you press Duplicate on a card.
    TEXT
    code_sample: <<~RUBY
      result = RecordingStudioDuplicatable::Services::DuplicationService.call(
        recording: page_recording,
        actor: current_user
      )
    RUBY
  },
  {
    slug: "methods",
    title: "Methods",
    summary: "Review the main API entry points exposed by the duplicatable addon.",
    body: <<~TEXT,
      The addon exposes a small surface area.

      Use the capability module to opt into duplication, use duplicate_in_place! when you already have a recording instance, and use the service object for controller-friendly success and failure handling.
    TEXT
    code_sample: nil
  }
].freeze

user = User.find_or_create_by!(email: "admin@admin.com") do |u|
  u.password = "Password"
  u.password_confirmation = "Password"
end

workspace = Workspace.find_or_create_by!(name: "Documentation Workspace")

root_recording = RecordingStudio::Recording.unscoped.find_or_create_by!(
  recordable: workspace,
  parent_recording_id: nil
)

Current.actor = user
access = RecordingStudio::Access.find_or_create_by!(actor: user, role: :admin)
RecordingStudio::Recording.unscoped.find_or_create_by!(
  root_recording_id: root_recording.id,
  parent_recording_id: root_recording.id,
  recordable: access
)

PAGE_DEFINITIONS.each do |attributes|
  page = workspace.pages.find_or_initialize_by(slug: attributes[:slug])
  page.assign_attributes(attributes)
  page.save!

  RecordingStudio::Recording.unscoped.find_or_create_by!(
    recordable: page,
    root_recording_id: root_recording.id,
    parent_recording_id: root_recording.id
  )
end

puts "Seeded: admin@admin.com / Password"
puts "Seeded: Workspace '#{workspace.name}' with root recording ##{root_recording.id}"
puts "Seeded: #{workspace.pages.count} demo pages"
