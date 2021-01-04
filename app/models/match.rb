class Match < ApplicationRecord
  belongs_to :game_map, optional: true
  belongs_to :discord_channel
  has_many :teams, dependent: :destroy
  has_many :players, through: :teams

  scope :ratings_not_processed, -> { where(ratings_processed: nil) }
  scope :history, -> { includes(:game_map).includes(:discord_channel).includes(teams: :players).order('id DESC') }

  def winning_team
    teams.find { |team| team.result == 1 }
  end
end
