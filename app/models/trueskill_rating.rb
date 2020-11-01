class TrueskillRating < ApplicationRecord
  belongs_to :player

  def rating
    (skill - (3 * deviation)) * 100
  end
end
