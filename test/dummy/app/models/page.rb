class Page < ApplicationRecord
  include RecordingStudioDuplicatable::Capabilities::Duplicatable.with(
    prefix: nil,
    suffix: " (Copy)",
    include_children: nil,
    exclude_children: nil
  )

  belongs_to :workspace

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: { scope: :workspace_id }

  before_validation :ensure_slug

  def initialize_dup(other)
    super
    self.slug = nil
  end

  private

  def ensure_slug
    base_slug = slug.presence || title.to_s.parameterize.presence || "page"
    self.slug = unique_slug_for(base_slug)
  end

  def unique_slug_for(base_slug)
    candidate = base_slug
    scope = self.class.where(workspace_id: workspace_id)
    scope = scope.where.not(id: id) if persisted?

    suffix = 2
    while scope.exists?(slug: candidate)
      candidate = "#{base_slug}-#{suffix}"
      suffix += 1
    end

    candidate
  end
end
