class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true

  validates :author_name, presence: true
  validates :body, presence: true
end
