# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in recording_studio_duplicatable.gemspec
gemspec

gem "recording_studio", github: "bowerbird-app/RecordingStudio", tag: "v4.2.0"
# Accessible 0.6.0 (RecordingStudio 4 support) — switch to tag "v0.6.0" once released.
# See https://github.com/bowerbird-app/RecordingStudio_accessible/pull/13
gem "recording_studio_accessible",
    github: "bowerbird-app/RecordingStudio_accessible",
    ref: "fd297891275d60998e5c7b7b250fc24505f7c469"

gem "puma"
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
