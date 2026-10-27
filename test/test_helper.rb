# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require_relative "simplecov_helper"
require "minitest/autorun"
require "minitest/mock"
require "rails"
require "recording_studio_duplicatable"
require "recording_studio/controller_layout"

unless defined?(RecordingStudio::LayoutHelper)
  module RecordingStudio
    module LayoutHelper
    end
  end
end

ActiveSupport.on_load(:action_controller_base) do
  include RecordingStudio::ControllerLayout
end

ActionController::Base.include(RecordingStudio::ControllerLayout) if defined?(ActionController::Base)
