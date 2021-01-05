require 'saulabs/trueskill'

class Api::V1::FairTeamsController < ApplicationController
  include Saulabs::TrueSkill

  def new
    players = players_params.map do |discord_id|
      Player.includes(:trueskill_rating).find_or_create_by(discord_id: discord_id)
    end

    teamsize = players.size / 2

    player1 = players.shift
    team1_combinations = players.combination(teamsize - 1)

    matchups = []

    team1_combinations.each do |combo|
      team1 = combo + [player1]
      team2 = players - combo

      teams = {}

      teams[team1] = team1.inject(0) do |sum, player|
        sum + player.trueskill_rating.conservative_skill_estimate
      end

      teams[team2] = team2.inject(0) do |sum, player|
        sum + player.trueskill_rating.conservative_skill_estimate
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
end
