require 'saulabs/trueskill'

class CleanUpResults < ActiveRecord::Migration[7.0]
  include Saulabs::TrueSkill

  def up
    # delete invalid discord channels
    DiscordChannel.where(name: nil).each { |dc| dc.destroy }

    # remove incomplete matches
    unfinished_matches = Match.select { |m| m.teams.any? { |t| t.result.nil? } }
    unfinished_matches.each { |m| m.destroy }

    # merge Oceania match histories
    oce = DiscordChannel.find_by(name: "FortressOne #oceania")
    tourny = DiscordChannel.find_by(name: "FortressOne #tournament")
    snoozer = DiscordChannel.find_by(name: "FortressOne #snoozerlan")

    [tourny, snoozer].each do |dc|
      dc.discord_channel_players.each do |dcp|
        oce_dcp = DiscordChannelPlayer.find_or_create_by(discord_channel_id: oce.id, player_id: dcp.player_id)

        dcp.discord_channel_player_teams.each do |dcpt|
          dcpt.update(discord_channel_player_id: oce_dcp.id)
        end

        dcp.discord_channel_player_rounds.each do |dcpr|
          dcpr.update(discord_channel_player_id: oce_dcp.id)
        end
      end

      dc.matches.update_all(discord_channel_id: oce.id)
      dc.discord_channel_players.update_all(discord_channel_id: oce.id)
      dc.destroy
    end

    # merge NA match histories
    na = DiscordChannel.find_by(name: "FortressOne #north-america")
    klowns = DiscordChannel.find_by(name: "QuakeWorld Team Fortress #🔫pick-up-games")
    coaches = DiscordChannel.find_by(name: "The Coach's Office #fo-pickups")

    [klowns, coaches].each do |dc|
      dc.discord_channel_players.each do |dcp|
        na_dcp = DiscordChannelPlayer.find_or_create_by(discord_channel_id: na.id, player_id: dcp.player_id)

        dcp.discord_channel_player_teams.each do |dcpt|
          dcpt.update(discord_channel_player_id: na_dcp.id)
        end

        dcp.discord_channel_player_rounds.each do |dcpr|
          dcpr.update(discord_channel_player_id: na_dcp.id)
        end
      end

      dc.matches.update_all(discord_channel_id: na.id)
      dc.discord_channel_players.update_all(discord_channel_id: na.id)
      dc.destroy
    end

    # recalculate ratings
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

  def down
  end
end
