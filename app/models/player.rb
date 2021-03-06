class Player < ApplicationRecord
  include ResultConstants

  has_and_belongs_to_many :teams
  has_many :matches, through: :teams
  has_many :discord_channel_players, dependent: :destroy
  has_many :discord_channels, through: :discord_channel_players

  scope :visible, ->{ where(invisible: false) }

  def match_count
    matches.size
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
    teams.where(result: int).size
  end
end
