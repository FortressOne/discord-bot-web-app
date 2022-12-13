class PlayersController < ApplicationController
  add_breadcrumb "Home", :root_path

  def index
    @players = Player.all
    add_breadcrumb "Players"
  end

  def show
    @player = Player.find(params[:id])
    add_breadcrumb "Players", players_path
    add_breadcrumb @player.name
  end
end
