# frozen_string_literal: true

namespace :tailwind do
  desc "Symlink gem component and view paths so Tailwind can scan them"
  task link_gem_sources: :environment do
    dest_root = Rails.root.join("tmp/tailwind_scan")
    FileUtils.mkdir_p(dest_root)

    sources = {}
    if defined?(FlatPack::Engine)
      sources[dest_root.join("flat_pack/app/components")] = FlatPack::Engine.root.join("app/components")
    end
    if defined?(RecordingStudio::Engine)
      sources[dest_root.join("recording_studio/app/views")] = RecordingStudio::Engine.root.join("app/views")
    end

    sources.each do |dest, src|
      next unless src.exist?

      FileUtils.mkdir_p(dest.dirname)
      FileUtils.rm_rf(dest) if dest.symlink? || dest.exist?
      FileUtils.ln_s(src.realpath, dest)
    end
  end
end
