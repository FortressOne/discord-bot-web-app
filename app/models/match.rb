require 'saulabs/trueskill'

class Match < ApplicationRecord
  include ResultConstants
  include Saulabs::TrueSkill

  belongs_to :game_map, optional: true
  belongs_to :discord_channel
  belongs_to :server, optional: true
  has_many :teams, dependent: :destroy
  has_many :rounds, dependent: :destroy
  has_many :players, through: :teams
  has_many :discord_channel_players, through: :teams

  scope :ratings_not_processed, -> { where(ratings_processed: nil) }

  scope :history, -> do
    order(created_at: :desc)
      .includes(:game_map)
      .includes(teams: :players)
  end

  def description
    if drawn?
      "Draw"
    elsif winning_team.name == "1"
      if scores["1"] && scores["2"]
        "Blue wins by #{scores["1"] - scores["2"]} points"
      else
        "Blue wins"
      end
    elsif winning_team.name == "2"
      if scores["1"] && scores["2"]
        "Red wins with #{seconds_to_str(time_left)} remaining"
      else
        "Red wins"
      end
    end
  end

  def size
    teams.map { |team| team.size }.join("v")
  end

  def update_trueskill_ratings
    puts "updating match id: #{id}"

    team1_player_ratings = team(1).trueskill_ratings_rating_objs
    team2_player_ratings = team(2).trueskill_ratings_rating_objs

    FactorGraph.new(
      team1_player_ratings => team(1).rank,
      team2_player_ratings => team(2).rank
    ).update_skills

    team(1).update_ratings(team1_player_ratings)
    team(2).update_ratings(team2_player_ratings)

    ratings_processed = true
    save
  end

  def team_for(discord_channel_player)
    teams.first do |team|
      team.discord_channel_players.includes?(discord_channel_player)
    end
  end

  def score
    team(1).score && "#{team(1).score} — #{team(2).score}"
  end

  def scores
    Hash[teams.map { |t| [t.name, t.score] }]
  end

  def winning_team
    teams.find { |team| team.result == WIN }
  end

  def drawn?
    teams.all? { |team| team.result == DRAW }
  end

  def map_name
    game_map && game_map.name
  end

  def team(n)
    teams.find { |team| team.name == n.to_s }
  end

  def result_colour
    return COLOUR[:draw] if drawn?
    return COLOUR[:blue] if winning_team.name == "1"
    return COLOUR[:red] if winning_team.name == "2"
  end

  private

  def seconds_to_str(seconds)
    ["#{seconds / 3600}h", "#{seconds / 60 % 60}m", "#{seconds % 60}s"]
      .select { |str| str =~ /[1-9]/ }.join(" ")
  end
end
