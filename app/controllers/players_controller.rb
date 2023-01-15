class PlayersController < ApplicationController
  add_breadcrumb "Home", :root_path

  def index
    @players = Player.all.sort_by(&:match_count).reverse
    add_breadcrumb "Players"
  end

  def show
    @player = Player.find(params[:id])
    add_breadcrumb "Players", players_path
    add_breadcrumb @player.name
  end

  def rotate_token
    authenticate_player!
    current_player.regenerate_auth_token
    @player = Player.find(params[:id])
    render :show
  end
end
