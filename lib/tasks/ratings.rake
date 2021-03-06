require 'saulabs/trueskill'

namespace :ratings do
  desc "build ratings from scratch"
  task build: :environment do
    include Saulabs::TrueSkill

    TrueskillRating.destroy_all

    Match.all.each do |match|
      match.update_trueskill_ratings
    end
  end
end
