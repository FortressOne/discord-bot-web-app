class DiscordChannelPlayer < ApplicationRecord
  WIN = 1
  LOSS = -1
  DRAW = 0

  has_one :trueskill_rating
  belongs_to :discord_channel
  belongs_to :player
  has_and_belongs_to_many :teams

  before_create :build_default_trueskill_rating

  def match_count
    result_count
  end

  def win_count
    result_count(WIN)
  end

  def loss_count
    result_count(LOSS)
  end

  def draw_count
    result_count(DRAW)
  end

  private

  def result_count(result_int = nil)
    matches = player.matches.where(discord_channel_id: discord_channel.id)

    if result_int
      matches = matches
        .joins(teams: :players)
        .where(
          teams: {
            result: result_int,
            players: { id: player.id }
          }
        )
    end

    matches.count
  end

  def build_default_trueskill_rating
    build_trueskill_rating
    true
  end
end
