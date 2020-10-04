class PlayersController < ApplicationController
  def index
    @players = Player.last_match_order
  end
end
