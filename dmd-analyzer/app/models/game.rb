class Game < ApplicationRecord
  has_many :events

  def self.ensure!(game_id)
    find_or_create_by(uuid: game_id)
  end

  def calculate_high_score
    events.where(type: :update_score).maximum("(metadata->>'value')::integer")
  end
end
