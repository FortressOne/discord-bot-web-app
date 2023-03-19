class Team < ApplicationRecord
  include ResultConstants

  RANKS = { WIN => 1, DRAW => 1, LOSS => 2 }.freeze
  COLOUR = { 1 => "blue", 2 => "red", 3 => "yellow", 4 => "green" }.freeze

  DEFAULT_FLAG = { url: "home/flags/flag_0.png", alt: "Quartered flag" }
  FLAGS = {
    1 => { url: "home/flags/flag_1.png", alt: "Blue flag" },
    2 => { url: "home/flags/flag_2.png", alt: "Red flag" },
    3 => { url: "home/flags/flag_3.png", alt: "Yellow flag" },
    4 => { url: "home/flags/flag_4.png", alt: "Green flag" },
  }

  belongs_to :match
  has_many :discord_channel_player_teams, dependent: :destroy
  has_many :discord_channel_players, through: :discord_channel_player_teams
  has_many :players, through: :discord_channel_players
  has_many :trueskill_ratings, through: :discord_channel_players

  def size
    discord_channel_player_teams_count
  end

  def description
    "#{colour.titleize} Team"
  end

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

      dcpt = discord_channel_player_teams.find_by(
        discord_channel_player: tr.trueskill_rateable
      )

      if dcpt.trueskill_rating.nil?
        dcpt.create_trueskill_rating
      end

      dcpt
        .trueskill_rating
        .update(mean: rating.mean, deviation: rating.deviation)
    end
  end

  def flag
    FLAGS.fetch(number, DEFAULT_FLAG)
  end
end
