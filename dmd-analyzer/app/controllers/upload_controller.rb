class UploadController < ApplicationController
  protect_from_forgery with: :null_session

  def events
    params.fetch(:events).each do |event|
      uuid = event.delete(:game_id)
      next unless uuid
      game = Game.ensure!(uuid)

      n = event.delete(:player_number) || next
      type = event.delete(:type) || next
      t = event.delete(:t)

      game.events.create!(
        type: type,
        player_number: n,
        occured_at: Time.now, # TODO
        metadata: event
      )
    end
  end
end
