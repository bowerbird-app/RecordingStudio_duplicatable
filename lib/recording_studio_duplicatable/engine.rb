# frozen_string_literal: true

module RecordingStudioDuplicatable
  class Engine < ::Rails::Engine
    isolate_namespace RecordingStudioDuplicatable

    initializer "recording_studio_duplicatable.load_config" do |app|
      if app.respond_to?(:config_for)
        begin
          yaml = begin
            app.config_for(:recording_studio_duplicatable)
          rescue StandardError
            nil
          end
          RecordingStudioDuplicatable.configuration.merge!(yaml) if yaml.respond_to?(:each)
        rescue StandardError => _e
          # ignore load errors; host app can provide initializer overrides
        end
      end

      # Merge Rails.application.config.x.recording_studio_duplicatable if present
      if app.config.respond_to?(:x) && app.config.x.respond_to?(:recording_studio_duplicatable)
        xcfg = app.config.x.recording_studio_duplicatable
        if xcfg.respond_to?(:to_h)
          RecordingStudioDuplicatable.configuration.merge!(xcfg.to_h)
        else
          begin
            # try converting OrderedOptions
            hash = {}
            xcfg.each_pair { |k, v| hash[k] = v } if xcfg.respond_to?(:each_pair)
            RecordingStudioDuplicatable.configuration.merge!(hash) if hash&.any?
          rescue StandardError => _e
            # ignore
          end
        end
      end
    end

    initializer "recording_studio_duplicatable.apply_recording_studio_capabilities",
                after: "recording_studio.after_initialize" do
      RecordingStudioDuplicatable.apply_recording_studio_capabilities!
    end
  end
end
