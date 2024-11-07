require 'saulabs/trueskill'

class Results::Api::V1::FairTeamsController < ApplicationController
  include Saulabs::TrueSkill

  def new
    Rails.logger.info("AAAAAAAAAAAAAAAAAAAAAAA")

    discord_channel = DiscordChannel.find_or_create_by(
      channel_id: discord_channel_id_params
    )

    Rails.logger.info("BBBBBBBBBBBBBBBBBBBB")

    discord_channel_players = players_params.map do |discord_id|
      DiscordChannelPlayer.find_or_create_by(
        player_id: Player.find_or_create_by(discord_id: discord_id).id,
        discord_channel_id: discord_channel.id
      )
    end

    teamsize = discord_channel_players.size / 2

    Rails.logger.info("CCCCCCCCCCCCCCCCCCCCcc")

    player1 = discord_channel_players.shift
    team1_combinations = discord_channel_players.combination(teamsize - 1)

    Rails.logger.info("DDDDDDDDDDDDDDDDDDDDDDD")

    matchups = team1_combinations.inject([]) do |matchups, combo|
      team1 = combo + [player1]
      team2 = discord_channel_players - combo

      teams = {}

      teams[team1] = team1.inject(0) do |sum, discord_channel_player|
        sum + discord_channel_player.conservative_skill_estimate
      end

      teams[team2] = team2.inject(0) do |sum, discord_channel_player|
        sum + discord_channel_player.conservative_skill_estimate
      end

      if discord_channel.matches.count.odd?
        teams = teams.to_a.reverse.to_h
      end

      matchups << teams
    end

    Rails.logger.info("EEEEEEEEEEEEEEEEEEEEEEEEEEE")

    sorted_matchups = matchups.sort_by do |matchup|
      Matchup.new(matchup).difference
    end

    Rails.logger.info("FFFFFFFFFFFFFFFFFFFFFFF")

    results = sorted_matchups.inject([]) do |results, matchup|
      results << Matchup.new(matchup).teams
    end

    Rails.logger.info("GGGGGGGGGGGGGGGGGGGGGGGGGGG")

    Rails.logger.info("==============================")
    Rails.logger.info(results.to_json)
    Rails.logger.info("==============================")

    render json: results.to_json, status: :ok
  end

  private

  def players_params
    params.require(:players)
  end

  def discord_channel_id_params
    params.require(:channel_id)
  end
end
