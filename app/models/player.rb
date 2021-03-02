class Player < ApplicationRecord
  has_and_belongs_to_many :teams
  has_many :matches, through: :teams
  has_one :trueskill_rating, dependent: :destroy

  before_create :build_default_trueskill_rating

  scope :leaderboard, -> do
    where.not(invisible: true)
      .includes(:trueskill_rating)
      .includes(:matches)
      .sort_by do |player|
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

  def build_default_trueskill_rating
    build_trueskill_rating
    true
  end
end
