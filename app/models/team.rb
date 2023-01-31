class Team < ApplicationRecord
  include ResultConstants

  RANKS = { WIN => 1, DRAW => 1, LOSS => 2 }.freeze
  COLOUR = { 1 => "blue", 2 => "red", 3 => "yellow", 4 => "green" }.freeze

  belongs_to :match
  has_many :discord_channel_player_teams, dependent: :destroy
  has_many :discord_channel_players, through: :discord_channel_player_teams
  has_many :players, through: :discord_channel_players
  has_many :trueskill_ratings, through: :discord_channel_players

  def rank
    RANKS[result]
  end

  def colour
    COLOUR[number]
  end

  def number
    name.to_i
  end

  def emoji
    Rails.application.config.team_emojis[number]
  end

  def trueskill_ratings_rating_objs
    trueskill_ratings.map(&:to_rating)
  end

  def update_ratings(player_ratings)
    trueskill_ratings.each_with_index do |tr, i|
      rating = player_ratings[i]
      tr.mean = rating.mean
      tr.deviation = rating.deviation
      tr.save

      dcpts = discord_channel_player_teams.find_by(
        discord_channel_player: tr.trueskill_rateable
      )

      dcpts
        .create_trueskill_rating
        .update(mean: rating.mean, deviation: rating.deviation)
    end
  end
end
