class Api::V1::MatchesController < ActionController::API
  def create
    match = Match.create

    match_params[:teams].each do |name, attrs|
      team = match.teams.new

      attrs[:players].each do |discord_id, display_name|
        player = Player.find_or_create_by(discord_id: discord_id)
        player.name = display_name
        player.save
        team.players << player
      end

      team.result = attrs[:result].to_i
      team.save
    end

    match.game_map = map_params && GameMap.find_or_create_by(name: map_params)
    match.save

    render json: match.id.to_json, status: :ok
  end

  private

  def map_params
    match_params[:map]
  end

  def match_params
    params.require(:match).permit(:winner, :map, { teams: {} })
  end
end
