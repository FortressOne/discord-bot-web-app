class DiscordChannelPlayer < ApplicationRecord
  WIN = 1
  LOSS = -1
  DRAW = 0

  has_one :trueskill_rating
  belongs_to :discord_channel
  belongs_to :player
  has_and_belongs_to_many :teams

  def match_count
    teams.count
  end

  def win_count
    teams.where(result: WIN).count
  end

  def loss_count
    teams.where(result: LOSS).count
  end

  def draw_count
    teams.where(result: DRAW).count
  end
end
