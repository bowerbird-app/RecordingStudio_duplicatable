# frozen_string_literal: true

# Trashable v0.11.0 still includes this module. Recording Studio 6.1 removed
# it. Defining it here lets that engine eager-load in the dummy app.
# Duplicatable and the host controller do not include it.
module RecordingStudio
  module UsesDefaultLayout
    extend ActiveSupport::Concern

    included do
      recording_studio_layout { nil }
    end
  end
end
