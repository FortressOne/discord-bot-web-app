class PlayersController < ApplicationController
  def index
    @players = Player.leaderboard
  end
end
