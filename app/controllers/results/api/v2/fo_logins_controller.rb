class Results::Api::V2::FoLoginsController < ActionController::API
  def create
    @player = Player.find_by(fo_login_params)

    if @player
      render json: { player: { id: @player.id, name: @player.name, token: @player.auth_token } }
    else
      render json: "Login failed.", status: 403
    end
  end

  private

  def fo_login_params
    params.require(:fo_login).permit(:auth_token)
  end
end
