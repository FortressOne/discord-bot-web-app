class PlayersController < ApplicationController
  add_breadcrumb "Home", :root_path

  before_action :set_player, only: [:update, :rotate_token]
  before_action :authorize_player, only: [:update, :rotate_token]

  def index
    @players = Player
      .joins(:teams)
      .includes(:teams)
      .sort_by(&:last_match_date)
      .reverse

    add_breadcrumb "Players"
  end

  def show
    @player = Player
      .includes(discord_channel_players: [:discord_channel, :teams])
      .find(params[:id])

    add_breadcrumb "Players", players_path
    add_breadcrumb @player.name
  end

  def update
    if @player.update(player_params)
      render json: { status: :ok }
    else
      render json: @player.errors, status: :unprocessable_entity
    end
  end

  def rotate_token
    current_player.regenerate_auth_token
    render :show
  end

  private

  def authorize_player
    if @player != current_player
      render(
        json: { error: 'Not Authorized' },
        status: 403
      )
    end
  end

  def player_params
    params.require(:player).permit(:public_ratings)
  end

  def set_player
    @player = Player.find(params[:id])
  end
end
