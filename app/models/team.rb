class Team < ApplicationRecord
  belongs_to :match
  has_and_belongs_to_many :players

  default_scope { order(created_at: :asc) }

  def rank
    case result
    when 1 then 1
    when 0 then 1
    when -1 then 2
    end
  end

  def player_ratings(discord_channel_id)
    players.map do |player|
      trueskill_rating = trueskill_rating(player)
      Rating.new(trueskill_rating.mean, trueskill_rating.deviation)
    end
  end

  def update_ratings(player_ratings)
    players.each_with_index do |player, i|
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

  private

  def trueskill_rating(player)
    discord_channel_player = player.discord_channel_players.find_or_create_by(
      discord_channel_id: match.discord_channel_id
    )

    TrueskillRating.find_or_create_by(discord_channel_player_id: discord_channel_player.id)
  end
end
