class Team < ApplicationRecord
  belongs_to :match
  has_and_belongs_to_many :players
  has_and_belongs_to_many :discord_channel_players
  has_many :trueskill_ratings, through: :discord_channel_players

  default_scope { order(created_at: :asc) }

  def rank
    case result
    when 1 then 1
    when 0 then 1
    when -1 then 2
    end
  end

  def trueskill_ratings_rating_objs
    trueskill_ratings.map(&:to_rating)
  end

  def update_ratings(player_ratings)
    discord_channel_players.each_with_index do |dcp, i|
      rating = player_ratings[i]

      trueskill_rating = trueskill_rating(player)
      trueskill_rating.mean = rating.mean
      trueskill_rating.deviation = rating.deviation
      trueskill_rating.save

      player.save

      puts '===='
      puts player.name
      puts trueskill_rating.mean
    end
  end
end
