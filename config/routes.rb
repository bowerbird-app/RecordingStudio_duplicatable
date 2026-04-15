# frozen_string_literal: true

RecordingStudioDuplicatable::Engine.routes.draw do
  post "recordings/:recording_id/duplicate", to: "duplications#create", as: :duplicate_recording
  root "home#index"
end
