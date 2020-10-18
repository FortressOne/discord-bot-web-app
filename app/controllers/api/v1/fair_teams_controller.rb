require 'saulabs/trueskill'

class Api::V1::FairTeamsController < ApplicationController
  include Saulabs::TrueSkill

  def new
    players = player_params.map do |discord_id|
      Player.includes(:trueskill_rating).find_or_create_by(discord_id: discord_id)
    end

    player1 = players.shift
    team1_combinations = players.combination(3)

    matchups = []

    team1_combinations.each do |combo|
      team1 = combo + [player1]
      team2 = players - combo

      teams = {}

      teams[team1] = team1.inject(0) do |sum, player|
        sum + player.trueskill_rating.skill
      end

      teams[team2] = team2.inject(0) do |sum, player|
        sum + player.trueskill_rating.skill
      end

      matchups << teams
    end

    sorted_matchups = matchups.each do |matchup|
      Matchup.new(matchup).difference
    end

    results = []

    sorted_matchups.each do |matchup|
      results << Matchup.new(matchup).teams
    end

    render json: results.to_json, status: :ok
  end

  private

  def player_params
    params.require(:players)
  end
end
