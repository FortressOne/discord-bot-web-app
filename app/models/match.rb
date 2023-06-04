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

  scope :completed, -> do
    order(created_at: :desc)
      .includes([
        :discord_channel,
        :server,
        :game_map,
        { teams: { discord_channel_player_teams: [
          :discord_channel_player_team_rounds,
          { discord_channel_player: :player },
        ]} },
      ])
          .joins(:teams)
          .group(:id)
          .having("COUNT(teams.id) > 1")
  end

  scope :for_teamsize, ->(teamsize) do
    joins(:teams)
      .where(teams: { name: '2', discord_channel_player_teams_count: teamsize })
      .distinct
  end

  scope :history, -> do
    order(created_at: :desc)
      .includes(:game_map)
      .includes(teams: :players)
  end

  def description
    if drawn?
      "Draw"
    elsif !winning_team
      "Match underway"
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
    if result.nil?
      puts "no result for id: #{id}" && nil
      return nil
    end

    puts "updating match id: #{id}"

    team1 = team(1)
    team2 = team(2)

    team1_player_ratings = team1.initial_trueskill_rating_objs
    team2_player_ratings = team2.initial_trueskill_rating_objs

    FactorGraph.new(
      team1_player_ratings => team1.rank,
      team2_player_ratings => team2.rank
    ).update_skills

    team1.update_ratings(team1_player_ratings)
    team2.update_ratings(team2_player_ratings)

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
    teams.present? && teams.find { |team| team.result == WIN }
  end

  def drawn?
    teams.present? && teams.all? { |team| team.result == DRAW }
  end

  def map_name
    game_map && game_map.name
  end

  def team(n)
    teams.find { |team| team.name == n.to_s }
  end

  def result_colour
    return COLOUR[:in_progress] if in_progress?
    return COLOUR[:draw] if drawn?
    return COLOUR[:blue] if winning_team.name == "1"
    return COLOUR[:red] if winning_team.name == "2"
  end

  def result
    return nil if teams.empty?
    return "in progress" if in_progress?
    return "draw" if drawn?
    return "blue wins" if winning_team.name == "1"
    return "red wins" if winning_team.name == "2"
  end

  def progress_value
    if result == "blue wins" && scores.values.any?
      600 + (scores["2"].to_f / scores["1"] * 600)
    elsif result == "red wins" && time_left
      1200 - time_left
    else
      1200
    end
  end

  private

  def in_progress?
    teams.present? && teams.none?(&:result)
  end

  def seconds_to_str(seconds)
    ["#{seconds / 3600}h", "#{seconds / 60 % 60}m", "#{seconds % 60}s"]
      .select { |str| str =~ /[1-9]/ }.join(" ")
  end
end
