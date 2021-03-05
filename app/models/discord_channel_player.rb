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

  private

  def build_default_trueskill_rating
    build_trueskill_rating
    true
  end
end
