class Game < ApplicationRecord
  has_many :events

  def self.ensure!(game_id)
    find_or_create_by(uuid: game_id)
  end
end
