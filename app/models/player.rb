class Player < ApplicationRecord
  WIN = 1
  LOSS = -1
  DRAW = 0

  has_and_belongs_to_many :teams
  has_many :matches, through: :teams
  has_many :trueskill_ratings, dependent: :destroy
  has_many :discord_channel_players
  has_many :discord_channels, through: :discord_channel_players

  scope :global_leaderboard, -> do
    where
      .not(invisible: true)
      .joins(:trueskill_ratings)
      .where(trueskill_ratings: { discord_channel_id: nil })
      .sort_by do |player|
        player
          .trueskill_ratings
          .find_by(discord_channel_id: discord_channel_id)
          .conservative_skill_estimate * -1
      end
  end

  scope :discord_channel_leaderboard, ->(discord_channel_id) do
    where
      .not(invisible: true)
      .joins(:trueskill_ratings)
      .where(trueskill_ratings: { discord_channel_id: discord_channel_id })
      .sort_by do |player|
        player
          .trueskill_ratings
          .find_by(discord_channel_id: discord_channel_id)
          .conservative_skill_estimate * -1
      end
  end

  def last_match_date
    matches.any? && matches.last.created_at
  end

  def last_discord_channel
    matches.any? && matches.last.discord_channel
  end

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
