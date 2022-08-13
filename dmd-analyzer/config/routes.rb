Rails.application.routes.draw do
  resources :games
  post '/api/upload/events', to: 'upload#events'
end
