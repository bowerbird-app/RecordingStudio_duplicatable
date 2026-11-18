# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in recording_studio_duplicatable.gemspec
gemspec

gem "recording_studio", github: "bowerbird-app/RecordingStudio", tag: "v7.7.1"
gem "recording_studio_accessible",
    github: "bowerbird-app/RecordingStudio_accessible",
    tag: "v0.54.1"
# Accessible pulls Trashable query-only; pin git sources for Bundler resolution.
gem "flat_pack", github: "bowerbird-app/flatpack", tag: "v0.1.378", require: false
gem "recording_studio_metrics", github: "bowerbird-app/RecordingStudio_metrics", tag: "v0.9.2",
                                require: false
gem "recording_studio_trashable", github: "bowerbird-app/RecordingStudio_trashable", tag: "v1.2.1",
                                  require: false
gem "view_component", "4.19.0"

gem "puma", "8.1.1"
gem "sprockets-rails"

group :development, :test do
  gem "debug"
  gem "minitest-mock"
  gem "simplecov", require: false
end

group :development do
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
end
