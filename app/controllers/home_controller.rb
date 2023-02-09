class HomeController < ApplicationController
  def index
    @matches = Match
      .order(created_at: :desc)
      .includes([
        :discord_channel,
        :server,
        :game_map,
        { teams: { discord_channel_player_teams: [
          :discord_channel_player_team_rounds,
          { discord_channel_player: :player },
        ]} },
      ]).limit(1)
  end
end
