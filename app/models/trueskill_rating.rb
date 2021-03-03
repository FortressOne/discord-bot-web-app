class TrueskillRating < ApplicationRecord
  belongs_to :discord_channel_player

  scope :global, ->{ where(discord_channel: nil) }

  def conservative_skill_estimate
    mean - 3 * deviation
  end
end
