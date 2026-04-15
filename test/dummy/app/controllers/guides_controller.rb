class GuidesController < ApplicationController
  GUIDE_CONTENT = {
    "setup" => {
      title: "Setup",
      subtitle: "Opt a recordable into duplication and define how child recordings should behave.",
      sections: [
        {
          title: "Capability",
          subtitle: "Include the addon with the child-copy options you want.",
          code_block: {
            title: "Page configuration",
            language: "ruby",
            code: <<~RUBY
              class Page < ApplicationRecord
                include RecordingStudioDuplicatable::Capabilities::Duplicatable.with(
                  prefix: nil,
                  suffix: " (Copy)",
                  include_children: ["Comment"],
                  exclude_children: nil
                )
              end
            RUBY
          }
        },
        {
          title: "Options",
          subtitle: "Use include/exclude options to control child duplication.",
          table: {
            data: [
              {option: "prefix", purpose: "Prepends text to the duplicate title or name"},
              {option: "suffix", purpose: "Appends text to the duplicate title or name"},
              {option: "include_children", purpose: "Copies only the listed child recording types"},
              {option: "exclude_children", purpose: "Skips the listed child recording types"}
            ]
          }
        },
        {
          title: "Report example",
          subtitle: "Reports can opt out of copying comment children.",
          code_block: {
            title: "Report configuration",
            language: "ruby",
            code: <<~RUBY
              class Report < ApplicationRecord
                include RecordingStudioDuplicatable::Capabilities::Duplicatable.with(
                  prefix: nil,
                  suffix: " (Copy)",
                  include_children: nil,
                  exclude_children: ["Comment"]
                )
              end
            RUBY
          }
        }
      ]
    },
    "use" => {
      title: "Use",
      subtitle: "Duplicate through the recording layer so Recording Studio keeps the copied tree attached correctly.",
      sections: [
        {
          title: "Service call",
          subtitle: "Pass a recording and actor into the service.",
          code_block: {
            title: "Controller usage",
            language: "ruby",
            code: <<~RUBY
              result = RecordingStudioDuplicatable::Services::DuplicationService.call(
                recording: page_recording,
                actor: current_user
              )
            RUBY
          }
        },
        {
          title: "Demo behavior",
          subtitle: "The dummy app shows both included and excluded child-copy rules.",
          table: {
            data: [
              {recordable: "Page", child_behavior: "Comments are duplicated"},
              {recordable: "Report", child_behavior: "Comments are excluded"}
            ]
          }
        }
      ]
    },
    "methods" => {
      title: "Methods",
      subtitle: "The main public entry points exposed by the duplicatable addon.",
      sections: [
        {
          title: "API surface",
          subtitle: "Use the model capability for setup and the service or recording for execution.",
          table: {
            data: [
              {
                method: "RecordingStudioDuplicatable::Capabilities::Duplicatable",
                purpose: "Enable duplication with global defaults"
              },
              {
                method: "RecordingStudioDuplicatable::Capabilities::Duplicatable.with(...)",
                purpose: "Enable duplication with per-type options"
              },
              {
                method: "recording.duplicate_in_place!(actor:, ...)",
                purpose: "Duplicate directly from a recording instance"
              },
              {
                method: "RecordingStudioDuplicatable::Services::DuplicationService.call(recording:, actor:, ...)",
                purpose: "Use the wrapped Result object in controllers and services"
              }
            ]
          }
        },
        {
          title: "Recording call",
          subtitle: "Call duplication directly when you already have the recording object.",
          code_block: {
            title: "Recording API",
            language: "ruby",
            code: <<~RUBY
              duplicate = recording.duplicate_in_place!(actor: current_user)
            RUBY
          }
        }
      ]
    }
  }.freeze

  def show
    @guide = GUIDE_CONTENT.fetch(params[:slug]) { raise ActiveRecord::RecordNotFound }
  end
end
