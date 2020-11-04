class TrueskillRating < ApplicationRecord
  belongs_to :player

  def conservative_skill_estimate
    skill - 3 * deviation
  end
end
