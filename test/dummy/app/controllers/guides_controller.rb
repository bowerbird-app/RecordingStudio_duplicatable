class GuidesController < ApplicationController
  GUIDE_CONTENT = {
    "setup" => {
      title: "Setup",
      subtitle: "Add the duplicatable capability to the recordable types you want to copy in place.",
      sections: [
        {
          title: "1. Include the capability",
          body: [
            "Choose the recordable type that should support in-place duplication.",
            "Use `.with(...)` when you want per-type prefix, suffix, or child-copy behaviour."
          ],
          code_sample: <<~RUBY
            class Page < ApplicationRecord
              include RecordingStudioDuplicatable::Capabilities::Duplicatable.with(
                prefix: nil,
                suffix: " (Copy)",
                include_children: ["Comment"],
                exclude_children: nil
              )
            end
          RUBY
        },
        {
          title: "2. Register the recordable type",
          body: [
            "Add the recordable class name to `RecordingStudio.configure` so recordings can be created for it."
          ],
          code_sample: <<~RUBY
            RecordingStudio.configure do |config|
              config.recordable_types = ["Workspace", "Page", "Report", "Comment"]
            end
          RUBY
        }
      ],
      table: {
        headers: ["Option", "What it controls"],
        rows: [
          ["prefix", "Text added before the duplicate title or name"],
          ["suffix", "Text added after the duplicate title or name"],
          ["include_children", "Only these child recording types are copied"],
          ["exclude_children", "All child recording types are copied except these" ]
        ]
      }
    },
    "use" => {
      title: "Use",
      subtitle: "Duplicate from the recording layer so the addon can preserve parent/root relationships correctly.",
      sections: [
        {
          title: "Duplicate through the service",
          body: [
            "Find the `RecordingStudio::Recording` for the recordable you want to copy.",
            "Pass the recording and the current actor into the service to get a success or failure result object."
          ],
          code_sample: <<~RUBY
            result = RecordingStudioDuplicatable::Services::DuplicationService.call(
              recording: page_recording,
              actor: current_user
            )
          RUBY
        },
        {
          title: "What the demo shows",
          body: [
            "Pages are configured with `include_children: [\"Comment\"]`, so their child comment recordings are copied.",
            "Reports are configured with `exclude_children: [\"Comment\"]`, so their child comment recordings are intentionally skipped."
          ]
        }
      ]
    },
    "methods" => {
      title: "Methods",
      subtitle: "The main public entry points exposed by the duplicatable addon.",
      sections: [
        {
          title: "API surface",
          body: [
            "Use the capability module on models, then duplicate through either the recording instance or the wrapped service object."
          ]
        }
      ],
      table: {
        headers: ["Method", "Purpose"],
        rows: [
          ["RecordingStudioDuplicatable::Capabilities::Duplicatable", "Enable duplication with global defaults"],
          ["RecordingStudioDuplicatable::Capabilities::Duplicatable.with(...)", "Enable duplication with per-type options"],
          ["recording.duplicate_in_place!(actor:, ...)", "Duplicate directly from a recording instance"],
          ["RecordingStudioDuplicatable::Services::DuplicationService.call(recording:, actor:, ...)", "Controller-friendly service wrapper that returns a Result object"],
          ["RecordingStudioDuplicatable::Hooks.run(:after_duplicate, recording)", "Hook point invoked after a duplicate recording is created"]
        ]
      }
    }
  }.freeze

  def show
    @guide = GUIDE_CONTENT.fetch(params[:slug]) { raise ActiveRecord::RecordNotFound }
  end
end
