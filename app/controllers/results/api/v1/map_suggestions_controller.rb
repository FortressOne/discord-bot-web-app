class Results::Api::V1::MapSuggestionsController < ActionController::API
  def create
    player = map_suggestion_params[:discord_player_id] && Player.find_or_create_by(
      discord_id: map_suggestion_params[:discord_player_id]
    )

    discord_channel = DiscordChannel.find_or_create_by(
      channel_id: map_suggestion_params[:discord_channel_id]
    )

    @map_suggestion = MapSuggestion.create(
      player: player,
      discord_channel: discord_channel
    )

    if @map_suggestion.save
      render json: @map_suggestion.suggestion.to_json, status: :ok
    else
      render json: @map_suggestion.errors, status: :unprocessable_entity
    end
  end

  private

  def map_suggestion_params
    params.require(:map_suggestion).permit([:discord_channel_id, :discord_player_id])
  end
end
