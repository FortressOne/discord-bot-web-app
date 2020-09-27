class Api::V1::MatchesController < ActionController::API
  def create
    match = Match.create

    match_params[:teams].each do |name, attrs|
      team = match.teams.new

      team.result = if attrs[:winner] == true
                      1
                    else
                      -1
                    end

      attrs[:players].each do |discord_id|
        player = Player.find_or_create_by(
          discord_id: discord_id
        )

        team.players << player
      end

      team.save
    end

    match.game_map = GameMap.find_or_create_by(name: match_params[:map]) if match_params[:map]
    match.save

    render json: match.to_json, status: :ok
  end

  def match_params
    params.require(:match).permit(:map, { teams: {} }) 
  end
end
