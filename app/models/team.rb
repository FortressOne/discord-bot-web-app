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
      trueskill_rating = player.trueskill_ratings.find_by(
        discord_channel_id: discord_channel_id
      )

      Rating.new(trueskill_rating.mean, trueskill_rating.deviation
    end
  end
end
