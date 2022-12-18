require 'saulabs/trueskill'

namespace :ratings do
  desc "build ratings from scratch"
  task build: :environment do
    include Saulabs::TrueSkill

    TrueskillRating.destroy_all

    DiscordChannelPlayer.all.each do |dcp|
      dcp.create_trueskill_rating
    end

    Match.all.each do |match|
      match.update_trueskill_ratings
    end
  end
end
