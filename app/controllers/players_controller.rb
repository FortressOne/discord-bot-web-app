class PlayersController < ApplicationController
  def index
    @players = Player.match_count_order
  end
end
