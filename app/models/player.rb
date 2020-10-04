class Player < ApplicationRecord
  has_and_belongs_to_many :teams
  has_many :matches, through: :teams

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
