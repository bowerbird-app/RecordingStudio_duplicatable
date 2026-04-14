# frozen_string_literal: true

require_relative "lib/gem_template/version"

Gem::Specification.new do |spec|
  spec.name        = "gem_template"
  spec.version     = GemTemplate::VERSION
  spec.authors     = ["Bowerbird"]
  spec.homepage    = "https://github.com/bowerbird-app/RecordingStudio_duplicatable"
  spec.summary     = "Recording Studio addon for in-place duplication"
  spec.description = "A Rails engine addon that provides an opt-in duplicatable capability for " \
                     "Recording Studio recordables, including recursive descendant duplication"
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/bowerbird-app/RecordingStudio_duplicatable"
  spec.metadata["changelog_uri"] = "https://github.com/bowerbird-app/RecordingStudio_duplicatable/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", "~> 8.1.0"
end
