class Team < ApplicationRecord
  include ResultConstants

  RANKS = { WIN => 1, DRAW => 1, LOSS => 2 }.freeze

  belongs_to :match
  has_and_belongs_to_many :discord_channel_players
  has_many :players, through: :discord_channel_players
  has_many :trueskill_ratings, through: :discord_channel_players

  def rank
    RANKS[result]
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
    end
  end
end
