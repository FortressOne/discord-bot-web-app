class Player < ApplicationRecord
  has_and_belongs_to_many :teams
  has_many :matches, through: :teams
  has_one :trueskill_rating

  before_create :build_default_trueskill_rating

  def last_match_date
    matches.any? && matches.last.created_at
  end

  def match_count
    matches.count
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
    teams.where(result: int).count
  end

  def build_default_trueskill_rating
    build_trueskill_rating
    true
  end
end
