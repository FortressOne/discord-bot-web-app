class MatchReport < ApplicationRecord
  validates :game_token, presence: true
  validates :report_type, presence: true

  scope :ended, -> { where(report_type: "end") }
end
