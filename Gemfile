# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in recording_studio_duplicatable.gemspec
gemspec

gem "recording_studio", github: "bowerbird-app/RecordingStudio", tag: "v0.1.0-alpha"
gem "recording_studio_accessible",
    github: "bowerbird-app/RecordingStudio_accessible",
    ref: "8a0e854249367c44ec882d9cf7190831faf9854c"

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
