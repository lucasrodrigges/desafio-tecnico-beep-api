Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  
  root "application#index"
  
  mount Rswag::Api::Engine => '/docs'
  mount Rswag::Ui::Engine => '/docs'
  mount ActionCable.server => '/cable'
  
  draw :hackernews
end
