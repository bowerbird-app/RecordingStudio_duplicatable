class GuidesController < ApplicationController
  GUIDE_CONTENT = {
    "setup" => {
      title: "Setup",
      subtitle: "Install Recording Studio Accessible first, apply its migrations, then mount the engine, keep your current actor available, and let duplication authorize through RecordingStudioAccessible.authorized?.",
      sections: [
        {
          anchor: "accessible-install",
          title: "Install Recording Studio Accessible first",
          subtitle: "Duplication depends on RecordingStudioAccessible.authorized?, so install and migrate Recording Studio Accessible before you use duplication.",
          code_block: {
            title: "Required access addon setup",
            language: "bash",
            code: <<~BASH
              bin/rails generate recording_studio_accessible:install
              bin/rails generate recording_studio_accessible:migrations
              bin/rails db:migrate
            BASH
          }
        },
        {
          anchor: "mount-and-actor-setup",
          title: "Setup route and controller",
          subtitle: "Mount the engine to use the gem-provided duplication route and controller with your existing Recording Studio actor resolver.",
          code_block: {
            title: "Built-in route and controller",
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
          title: "Add capability to recordable",
          anchor: "capability",
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
              { option: "prefix", purpose: "Prepends text to the duplicate title or name" },
              { option: "suffix", purpose: "Appends text to the duplicate title or name" },
              { option: "include_children", purpose: "Copies only the listed child recording types" },
              { option: "exclude_children", purpose: "Skips the listed child recording types" }
            ]
          }
        }
      ]
    },
    "approach" => {
      title: "Approach",
      subtitle: "The gem keeps duplication deliberately narrow: duplicate the recording in place, keep the original recordable, and configure child-copy rules where the capability is declared.",
      sections: [
        {
          title: "General approach",
          subtitle: "Use the built-in flow when you want a simple in-place duplicate and predictable child-copy behavior.",
          list: {
            ordered: true,
            items: [
              "Duplicate is deliberately simple. Move or copy workflows belong in other Recording Studio addon gems.",
              "After duplication the default behavior is to refresh the current page. A prefix or suffix can be added to distinguish the new recording.",
              "Duplication copies the recording, not the recordable. The duplicate points to the existing recordable.",
              "Control of what child items are included in duplication lives in this gem through the capability options."
            ]
          }
        }
      ]
    },
    "use" => {
      title: "Use",
      subtitle: "How to duplicate something with the built-in route or your own host-app route and controller.",
      sections: [
        {
          anchor: "built-in-route",
          title: "Built-in route",
          subtitle: "Post to the mounted engine when you want a simple duplicate button or link; duplication authorization is handled by RecordingStudioAccessible.authorized?.",
          code_block: {
            title: "Simple button",
            language: "erb",
            code: <<~ERB
              <%# The built-in controller redirects back after duplication, so the current page reloads by default. %>
              <%= button_to "Duplicate",
                recording_studio_duplicatable.duplicate_recording_path(recording_id: page_recording.id),
                method: :post %>
            ERB
          }
        },
        {
          anchor: "custom-route-and-controller",
          title: "Custom route and controller",
          subtitle: "Add your own POST route and controller action when you want to control the path, redirect, or response.",
          code_block: {
            title: "Host app route and controller",
            language: "ruby",
            code: <<~RUBY
              post "/pages/:slug/duplicate", to: "pages#duplicate", as: :duplicate_page

              class PagesController < ApplicationController
                def duplicate
                  page = Page.find_by!(slug: params[:slug])
                  recording = RecordingStudio::Recording.find_by!(recordable: page)

                  result = RecordingStudioDuplicatable::Services::DuplicationService.call(
                    recording: recording,
                    actor: Current.actor
                  )

                  result.on_success do |duplicate_recording|
                    redirect_to page_path(duplicate_recording.recordable.slug), notice: "Page duplicated"
                  end.on_failure do |error|
                    redirect_to page_path(page.slug), alert: error.message
                  end
                end
              end
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
        }
      ]
    }
  }.freeze

  def show
    @guide = GUIDE_CONTENT.fetch(params[:slug]) { raise ActiveRecord::RecordNotFound }
  end
end
