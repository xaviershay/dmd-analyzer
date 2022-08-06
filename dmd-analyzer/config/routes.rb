Rails.application.routes.draw do
  post '/api/upload/events', to: 'upload#events'
end
