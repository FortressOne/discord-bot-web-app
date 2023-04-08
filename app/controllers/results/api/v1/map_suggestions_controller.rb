class Results::Api::V1::MapSuggestionsController < ActionController::API
  before_action :set_discord_channel, only: [:create, :vote]

  def create
    player = map_suggestion_params[:discord_player_id] && Player.find_or_create_by(
      discord_id: map_suggestion_params[:discord_player_id]
    )

    @map_suggestion = MapSuggestion.create(
      player: player,
      discord_channel: @discord_channel,
      for_teamsize: teamsize_params
    ).suggestion

    render json: @map_suggestion.to_json, status: :ok
  end

  def vote
    @map_suggestions = MapSuggestion.vote(
      discord_channel: @discord_channel,
      for_teamsize: teamsize_params
    )

    render json: @map_suggestions.to_json, status: :ok
  end

  private

  def set_discord_channel
    @discord_channel = DiscordChannel.find_or_create_by(
      channel_id: map_suggestion_params[:discord_channel_id]
    )
  end

  def map_suggestion_params
    params.require(:map_suggestion).permit([:discord_channel_id, :discord_player_id])
  end

  def size_params
    params[:size]
  end

  def teamsize_params
    params[:teamsize]
  end
end
