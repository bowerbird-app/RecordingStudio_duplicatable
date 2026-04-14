class Workspace < ApplicationRecord
  include GemTemplate::Capabilities::Duplicatable.with(
    prefix: nil,
    suffix: " (Copy)",
    include_children: nil,
    exclude_children: nil
  )
end
