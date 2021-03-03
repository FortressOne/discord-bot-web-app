class DiscordChannelPlayer < ApplicationRecord
  WIN = 1
  LOSS = -1
  DRAW = 0

  belongs_to :discord_channel
  belongs_to :player

  def match_count
    100
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

  def result_count(int)
    matches = player.matches.select do |match|
      match.discord_channel_id = discord_channel.id
    end

    matches.count
  end
end
