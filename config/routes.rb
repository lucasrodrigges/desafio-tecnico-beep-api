Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/docs'
  mount Rswag::Api::Engine => '/docs'
  mount ActionCable.server => '/cable'
  draw :hackernews
end
