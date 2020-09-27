class Api::V1::MatchesController < ActionController::API
  def create
    match = Match.create

    params[:match][:teams].each do |name, attrs|
      team = match.teams.new

      attrs[:players].each do |discord_id|
        player = Player.find_or_create_by(discord_id: discord_id)
        team.players << player
      end

      team.save
    end

    if params[:match][:map]
      match.game_map = GameMap.find_or_create_by(name: params[:match][:map])
    end

    match.save

    render json: match.to_json, status: :ok
  end
end
