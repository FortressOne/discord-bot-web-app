class TrueskillRating < ApplicationRecord
  belongs_to :player
  belongs_to :discord_channel, optional: true

  scope :global, ->{ where(discord_channel: nil) }

  def conservative_skill_estimate
    mean - 3 * deviation
  end
end
