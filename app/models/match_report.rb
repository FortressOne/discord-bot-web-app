class MatchReport < ApplicationRecord
  # Report types sent by ssqc/json.qc ReportMatchResult.
  REPORT_TYPES = %w[start round end unknown].freeze
  STRING_FIELDS = %w[game_token report_type map server_name server_address].freeze

  validates :game_token, presence: true
  validates :report_type, presence: true, inclusion: { in: REPORT_TYPES }
  validates(*STRING_FIELDS.map(&:to_sym), length: { maximum: 255 })

  scope :ended, -> { where(report_type: "end") }
end
