class GuidesController < ApplicationController
  GUIDE_CONTENT = {
    "setup" => {
      title: "Setup",
      subtitle: "Mount the engine, keep your current actor available, and opt recordables into duplication.",
      sections: [
        {
          title: "Mount and actor setup",
          subtitle: "The built-in duplicate endpoint uses the mounted engine route plus your existing Recording Studio actor resolver.",
          code_block: {
            title: "Routes and actor setup",
            language: "ruby",
            code: <<~RUBY
              mount RecordingStudioDuplicatable::Engine, at: "/recording_studio_duplicatable"

              RecordingStudio.configure do |config|
                config.actor = -> { Current.actor }
              end
            RUBY
          }
        },
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
      subtitle: "How to duplicate something with the built-in route, plus the custom option when you need it.",
      sections: [
        {
          code_block: {
            title: "Simple button",
            language: "erb",
            code: <<~ERB
              <%= button_to "Duplicate",
                recording_studio_duplicatable.duplicate_recording_path(recording_id: page_recording.id),
                method: :post %>
            ERB
          }
        },
        {
          title: "What gets copied",
          subtitle: "The dummy app shows the difference between included and excluded child recordings.",
          table: {
            data: [
              {recordable: "Page", child_behavior: "Comments are duplicated"},
              {recordable: "Report", child_behavior: "Comments are excluded"},
              {recordable: "Folder", child_behavior: "Nested folders and comments are duplicated"}
            ]
          }
        },
        {
          title: "Custom controller (optional)",
          subtitle: "Use the service directly when you want custom redirects or non-browser responses.",
          code_block: {
            title: "Service object",
            language: "ruby",
            code: <<~RUBY
              result = RecordingStudioDuplicatable::Services::DuplicationService.call(
                recording: page_recording,
                actor: current_user
              )
            RUBY
          }
        }
      ]
    },
    "methods" => {
      title: "Methods",
      subtitle: "The built-in endpoint is the simple option. The service and recording APIs are still there for custom workflows.",
      sections: [
        {
          title: "API surface",
          subtitle: "Use the route helper for simple UI actions, or drop down to the service and recording APIs when you need more control.",
          table: {
            data: [
              {
                method: "recording_studio_duplicatable.duplicate_recording_path(recording_id: ...)",
                purpose: "Post to the gem-provided controller from a button or link"
              },
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
          title: "Direct recording call",
          subtitle: "Call duplication directly when you already have the recording object and want full control in your own code.",
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
