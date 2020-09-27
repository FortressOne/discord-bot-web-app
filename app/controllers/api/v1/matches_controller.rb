class Api::V1::MatchesController < ActionController::API
  def create
    render json: {}.to_json, status: :ok
  end

  private

  def match_params
    params.require(:match).permit(:teams)
  end
end
