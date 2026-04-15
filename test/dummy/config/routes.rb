Rails.application.routes.draw do
  devise_for :users

  # RecordingStudio engine is data/API-focused and has no browser root route.
  # Keep legacy links working by redirecting the base path to the app home.
  get "/recording_studio", to: redirect("/"), as: nil
  mount RecordingStudio::Engine, at: "/recording_studio"
  mount RecordingStudioDuplicatable::Engine, at: "/recording_studio_duplicatable"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  get "guides/:slug", to: "guides#show", as: :guide
  get "pages/:slug", to: "home#show_page", as: :page
  get "reports/:slug", to: "home#show_report", as: :report
  get "folders/:slug", to: "home#show_folder", as: :folder
  root "home#index"
end
