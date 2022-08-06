class Initial < ActiveRecord::Migration[7.0]
  def change
    enable_extension 'pgcrypto'

    create_table :games do |t|
      t.datetime :created_at, null: false
      t.datetime :started_at
      t.datetime :completed_at
      t.integer :high_score, null: false, default: 0
      t.uuid :uuid, null: false
    end

    add_index :games, :uuid, unique: true

    create_table :events do |t|
      t.references :game, null: false, foreign_key: true
      t.string :type, null: false
      t.integer :player_number, null: false
      t.datetime :created_at, null: false
      t.datetime :occured_at, null: false
      t.jsonb :metadata, null: false, default: '{}'
    end

    create_table :players do |t|
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :initials, null: false
    end

    create_table :player_games do |t|
      t.references :game, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.integer :player_number, null: false
    end
  end
end
