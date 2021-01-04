class Team < ApplicationRecord
  belongs_to :match, counter_cache: true
  has_and_belongs_to_many :players
end
