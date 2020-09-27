class Player < ApplicationRecord
  has_and_belongs_to_many :teams
  has_many :matches, through: :teams
end
