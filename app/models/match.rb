class Match < ApplicationRecord
  belongs_to :game_map, optional: true
  has_many :teams
  has_many :players, through: :teams
end
