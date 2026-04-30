# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in recording_studio_duplicatable.gemspec
gemspec

gem "flat_pack", github: "bowerbird-app/flatpack", tag: "v0.1.33"

gem "recording_studio", github: "bowerbird-app/RecordingStudio", tag: "v0.1.0-alpha"
gem "recording_studio_accessible",
    github: "bowerbird-app/RecordingStudio_accessible",
    ref: "442afc0d91ee42e59b201a9ce963931ed1faa2e6"

gem "puma"
gem "sprockets-rails"

group :development, :test do
  gem "debug"
  gem "simplecov", require: false
end

group :development do
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
end
