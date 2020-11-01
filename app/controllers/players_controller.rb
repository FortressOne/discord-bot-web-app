class PlayersController < ApplicationController
  def index
    @players = Player.all.sort_by do |player|
      player.trueskill_rating.rating * -1
    end
  end
end
