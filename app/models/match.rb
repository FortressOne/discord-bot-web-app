class Match < ApplicationRecord
  belongs_to :game_map, optional: true
  has_many :teams
  has_many :players, through: :teams

  def winning_team
    teams.find { |team| team.result == 1 }
  end
end
