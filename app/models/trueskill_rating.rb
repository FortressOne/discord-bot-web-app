require 'saulabs/trueskill'

class TrueskillRating < ApplicationRecord
  include Saulabs::TrueSkill

  belongs_to :trueskill_rateable, polymorphic: true

  scope :global, ->{ where(discord_channel: nil) }

  def conservative_skill_estimate
    mean - 3 * deviation
  end

  def to_rating
    Rating.new(mean, deviation)
  end
end
