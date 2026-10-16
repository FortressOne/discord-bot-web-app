class Results::Api::V1::FoLoginsController < ActionController::API
  def create
    token = fo_login_params[:auth_token]
    # A blank token must never match: find_by({}) returns the first player.
    @player = Player.find_by(auth_token: token) if token.is_a?(String) && token.present?

    if @player
      render plain: "#{@player.name}##{@player.id}", status: :ok
    else
      render json: "Login failed.", status: 403
    end
  end

  private

  def fo_login_params
    params.require(:fo_login).permit(:auth_token)
  end
end
