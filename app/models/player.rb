class Player < ApplicationRecord
  has_and_belongs_to_many :teams
  has_many :matches, through: :teams

  scope :last_match_order, lambda {
    left_joins(:matches).group(:id).order('created_at DESC')
  }

  def last_match_date
    matches.last.created_at
  end

  def match_count
    matches.count
  end

  def win_count
    teams.where(result: 1).count
  end

  def loss_count
    teams.where(result: -1).count
  end

  def draw_count
    teams.where(result: 0).count
  end
end
