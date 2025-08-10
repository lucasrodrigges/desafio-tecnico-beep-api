Rails.application.routes.draw do
  if defined?(Rswag::Ui::Engine)
    mount Rswag::Ui::Engine => '/docs'
  end
  if defined?(Rswag::Api::Engine)
    mount Rswag::Api::Engine => '/docs'
  end
  mount ActionCable.server => '/cable'
  draw :hackernews
end
