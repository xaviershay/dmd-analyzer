class UploadController < ApplicationController
  protect_from_forgery with: :null_session

  def events
    params.fetch(:events).each do |event|
      uuid = event.delete(:game_id)
      next unless uuid
      game = Game.ensure!(uuid)

      n = event.delete(:player_number) || next
      type = event.delete(:type) || next
      t = Time.now # TODO: event.delete(:t)
      event.delete(:t)

      event = game.events.create!(
        type: type,
        player_number: n,
        occured_at: t,
        metadata: event
      )

      if type == "game_start"
        game.update!(started_at: t)
      elsif type == "game_end"
        game.update!(
          high_score: game.calculate_high_score,
          completed_at: t
        )
      end
    end
  end
end
