require 'saulabs/trueskill'

namespace :ratings do
  desc "build ratings from scratch"
  task build: :environment do
    include Saulabs::TrueSkill

    unfinished_matches = Match.select { |m| m.teams.any? { |t| t.result.nil? } }
    unfinished_matches.each { |m| m.destroy }

    puts "destroying all ratings"
    TrueskillRating.destroy_all

    puts "rating matches"
    Match.order(:created_at).each do |match|
      match.update_trueskill_ratings
    end

    puts "recalculating counter caches"
    DiscordChannelPlayer.counter_culture_fix_counts
    DiscordChannelPlayerTeam.counter_culture_fix_counts
  end
end
