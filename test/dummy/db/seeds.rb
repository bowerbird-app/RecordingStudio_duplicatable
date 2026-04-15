# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

DEMO_PAGES = [
  {
    slug: "launch-plan",
    title: "Launch Plan",
    summary: "A demo page whose comments should duplicate with it.",
    body: "Track the launch checklist, content approvals, and final release notes in one recordable page.",
    comments: [
      { author_name: "Avery", body: "Final copy is ready for review." },
      { author_name: "Parker", body: "Please keep the hero image in the duplicate too." }
    ]
  },
  {
    slug: "feature-brief",
    title: "Feature Brief",
    summary: "Another demo page that shows child comment copying.",
    body: "Capture the problem statement, acceptance notes, and rollout details for the new feature.",
    comments: [
      { author_name: "Quinn", body: "This duplicate should keep the stakeholder notes." },
      { author_name: "Riley", body: "Please preserve the nested recording structure." }
    ]
  }
].freeze

DEMO_REPORTS = [
  {
    slug: "weekly-kpis",
    title: "Weekly KPI Report",
    summary: "A demo report whose comments should be excluded from duplication.",
    comments: [
      { author_name: "Jordan", body: "These observations stay with the original report." },
      { author_name: "Sky", body: "The duplicate should start with zero comments." }
    ]
  },
  {
    slug: "incident-review",
    title: "Incident Review",
    summary: "Another report that demonstrates excluded child recordings.",
    comments: [
      { author_name: "Morgan", body: "Keep the follow-up notes attached only to the source report." }
    ]
  }
].freeze

DEMO_FOLDERS = [
  {
    slug: "product-docs",
    name: "Product Docs",
    description: "Top-level folder for recursive duplication.",
    comments: [
      { author_name: "Harper", body: "This folder should copy its nested folders too." }
    ],
    children: [
      {
        slug: "release-notes",
        name: "Release Notes",
        description: "Second-tier folder in the duplication tree.",
        comments: [
          { author_name: "Indy", body: "The middle tier should keep its own copied comments." }
        ],
        children: [
          {
            slug: "q2-launch",
            name: "Q2 Launch",
            description: "Third-tier folder that proves deep duplication.",
            comments: [
              { author_name: "Jules", body: "Deep nested folders should duplicate in place." }
            ]
          }
        ]
      }
    ]
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

def ensure_comment_recordings!(root_recording:, parent_recording:, recordable:, comments:)
  comments.each do |comment_attributes|
    comment = recordable.comments.find_or_initialize_by(author_name: comment_attributes[:author_name], body: comment_attributes[:body])
    comment.save!

    RecordingStudio::Recording.unscoped.find_or_create_by!(
      recordable: comment,
      root_recording_id: root_recording.id,
      parent_recording_id: parent_recording.id
    )
  end
end

def ensure_folder_recordings!(root_recording:, parent_recording:, workspace:, folder_attributes:, parent_folder: nil)
  folder = workspace.folders.find_or_initialize_by(slug: folder_attributes[:slug])
  folder.assign_attributes(
    folder_attributes.except(:comments, :children).merge(parent_folder: parent_folder)
  )
  folder.save!

  folder_recording = RecordingStudio::Recording.unscoped.find_or_create_by!(
    recordable: folder,
    root_recording_id: root_recording.id,
    parent_recording_id: parent_recording.id
  )

  ensure_comment_recordings!(
    root_recording: root_recording,
    parent_recording: folder_recording,
    recordable: folder,
    comments: folder_attributes[:comments] || []
  )

  Array(folder_attributes[:children]).each do |child_attributes|
    ensure_folder_recordings!(
      root_recording: root_recording,
      parent_recording: folder_recording,
      workspace: workspace,
      folder_attributes: child_attributes,
      parent_folder: folder
    )
  end
end

DEMO_PAGES.each do |attributes|
  page = workspace.pages.find_or_initialize_by(slug: attributes[:slug])
  page.assign_attributes(attributes.except(:comments))
  page.save!

  page_recording = RecordingStudio::Recording.unscoped.find_or_create_by!(
    recordable: page,
    root_recording_id: root_recording.id,
    parent_recording_id: root_recording.id
  )

  ensure_comment_recordings!(
    root_recording: root_recording,
    parent_recording: page_recording,
    recordable: page,
    comments: attributes[:comments]
  )
end

DEMO_REPORTS.each do |attributes|
  report = workspace.reports.find_or_initialize_by(slug: attributes[:slug])
  report.assign_attributes(attributes.except(:comments))
  report.save!

  report_recording = RecordingStudio::Recording.unscoped.find_or_create_by!(
    recordable: report,
    root_recording_id: root_recording.id,
    parent_recording_id: root_recording.id
  )

  ensure_comment_recordings!(
    root_recording: root_recording,
    parent_recording: report_recording,
    recordable: report,
    comments: attributes[:comments]
  )
end

DEMO_FOLDERS.each do |attributes|
  ensure_folder_recordings!(
    root_recording: root_recording,
    parent_recording: root_recording,
    workspace: workspace,
    folder_attributes: attributes
  )
end

puts "Seeded: admin@admin.com / Password"
puts "Seeded: Workspace '#{workspace.name}' with root recording ##{root_recording.id}"
puts "Seeded: #{workspace.pages.count} demo pages, #{workspace.reports.count} demo reports, #{workspace.folders.count} demo folders, #{Comment.count} demo comments"
