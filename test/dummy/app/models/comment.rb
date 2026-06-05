class Comment < ApplicationRecord
  recording_studio_recordable label: "Comment", root: false, allowed_parent_types: [ "Page", "Report", "Folder" ]

  belongs_to :commentable, polymorphic: true

  validates :author_name, presence: true
  validates :body, presence: true
end
