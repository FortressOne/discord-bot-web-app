class Player < ApplicationRecord
  has_and_belongs_to_many :teams
  has_many :matches, through: :teams
  has_many :trueskill_ratings, dependent: :destroy

  scope :global_leaderboard, -> do
    joins(:trueskill_ratings).merge(TrueskillRating.global)
      .sort_by do |player|
        player
          .trueskill_ratings
          .find_by(discord_channel_id: nil)
          .conservative_skill_estimate * -1
      end
  end

  scope :discord_channel_leaderboard, ->(discord_channel_id) do
    joins(:trueskill_ratings).where(
      trueskill_ratings: { discord_channel_id: discord_channel_id }
    ).sort_by do |player|
      player.trueskill_rating.conservative_skill_estimate * -1
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
    result_count(1)
  end

  def loss_count
    result_count(-1)
  end

  def draw_count
    result_count(0)
  end

  private

  def result_count(int)
    teams.where(result: int).size
  end
end
