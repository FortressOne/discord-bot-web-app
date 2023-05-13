require 'saulabs/trueskill'

namespace :ratings do
  desc "build ratings from scratch"
  task build: :environment do
    include Saulabs::TrueSkill

    unfinished_matches = Match.select { |m| m.teams.any? { |t| t.result.nil? } }
    unfinished_matches.each { |m| m.destroy }

    TrueskillRating.destroy_all

    DiscordChannelPlayer.all.each do |dcp|
      dcp.create_trueskill_rating
    end

    Match.order(:created_at).each do |match|
      match.update_trueskill_ratings
    end

    # recalculate counter_caches
    DiscordChannelPlayer.counter_culture_fix_counts
    DiscordChannelPlayerTeam.counter_culture_fix_counts
  end
end
