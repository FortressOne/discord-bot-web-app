class Match < ApplicationRecord
  belongs_to :game_map
  has_many :teams
  has_many :players, through: :teams
end
