require 'saulabs/trueskill'

class Match < ApplicationRecord
  include Saulabs::TrueSkill

  belongs_to :game_map, optional: true
  belongs_to :discord_channel
  has_many :teams, dependent: :destroy

  scope :ratings_not_processed, -> { where(ratings_processed: nil) }

  scope :history, -> do
    order(created_at: :desc)
      .includes(:game_map)
      .includes(teams: :players)
  end

  def winning_team
    teams.find { |team| team.result == 1 }
  end

  def update_trueskill_ratings
    team1 = teams.find_by(name: 1)
    team2 = teams.find_by(name: 2)

    team1_player_ratings = team1.trueskill_ratings_rating_objs
    team2_player_ratings = team2.trueskill_ratings_rating_objs

    FactorGraph.new(
      team1_player_ratings => team1.rank,
      team2_player_ratings => team2.rank
    ).update_skills

    team1.update_ratings(team1_player_ratings)
    team2.update_ratings(team2_player_ratings)

    ratings_processed = true
    save
  end
end
