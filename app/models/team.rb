class Team < ApplicationRecord
  belongs_to :match
  has_and_belongs_to_many :players

  default_scope { order(created_at: :asc) }
end
