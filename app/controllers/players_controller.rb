class PlayersController < ApplicationController
  def index
    @players = Player.all.sort_by do |player|
      player.trueskill_rating.skill * -1
    end
  end
end
