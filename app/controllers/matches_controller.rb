class MatchesController < ApplicationController
  before_action :set_match, only: %i[ show ]

  def index
    @matches = Match
      .includes([
        :server,
        :game_map,
        { teams: { discord_channel_player_teams: [
          :discord_channel_player_team_rounds,
          { discord_channel_player: :player },
        ]} },
      ])
          .last(100)
          .reverse
  end

  def show
  end

  private

  def set_match
    @match = Match.find(params[:id])
  end

  def match_params
    params.fetch(:match, {})
  end
end
