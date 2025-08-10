Rails.application.routes.draw do
  mount Rswag::Api::Engine => '/docs'
  mount Rswag::Ui::Engine => '/docs'
  mount ActionCable.server => '/cable'
  draw :hackernews
end
