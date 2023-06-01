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
  has_many :trueskill_ratings, through: :discord_channel_player_teams

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

  def initial_trueskill_rating_objs
    discord_channel_player_teams.order(:id).map do |dcpt|
      dcp = dcpt.discord_channel_player
      tr = dcp&.trueskill_rating || TrueskillRating.new
      tr.to_rating
    end
  end

  def update_ratings(player_ratings)
    discord_channel_player_teams.order(:id).each_with_index do |dcpt, i|
      new_rating = player_ratings[i]

      dcpt.create_trueskill_rating(
        mean: new_rating.mean,
        deviation: new_rating.deviation
      )
    end
  end

  def flag
    FLAGS.fetch(number, DEFAULT_FLAG)
  end
end
