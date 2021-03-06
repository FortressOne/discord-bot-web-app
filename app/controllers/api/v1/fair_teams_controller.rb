require 'saulabs/trueskill'

class Api::V1::FairTeamsController < ApplicationController
  include Saulabs::TrueSkill

  def new
    discord_channel_players = players_params.map do |discord_id|
      player = Player.find_or_create_by(discord_id: discord_id)

      discord_channel = DiscordChannel.find_or_create_by(
        channel_id: discord_channel_id_params
      )

      foo = DiscordChannelPlayer.find_or_create_by(
        player_id: player.id,
        discord_channel_id: discord_channel.id
      ).tap do |discord_channel_player|
        TrueskillRating.find_or_create_by(
          discord_channel_player_id: discord_channel_player.id
        )
      end
    end

    teamsize = discord_channel_players.size / 2

    player1 = discord_channel_players.shift
    team1_combinations = discord_channel_players.combination(teamsize - 1)

    matchups = []

    team1_combinations.each do |combo|
      team1 = combo + [player1]
      team2 = discord_channel_players - combo

      teams = {}

      teams[team1] = team1.inject(0) do |sum, discord_channel_player|
        sum + discord_channel_player.trueskill_rating.conservative_skill_estimate
      end

      teams[team2] = team2.inject(0) do |sum, discord_channel_player|
        sum + discord_channel_player.trueskill_rating.conservative_skill_estimate
      end

      matchups << teams
    end

    sorted_matchups = matchups.sort_by do |matchup|
      Matchup.new(matchup).difference
    end

    results = []

    sorted_matchups.each do |matchup|
      results << Matchup.new(matchup).teams
    end

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
