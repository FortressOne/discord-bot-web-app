class Results::Api::V1::MapSuggestionsController < ActionController::API
  RECENT_MAP_COUNT = 50

  def index
    json = MapSuggestion
      .index(channel_id: map_suggestion_params["discord_channel_id"])
      .to_json

    render(
      json: json,
      status: :ok
    )
  end

  def create
    @map_suggestion = MapSuggestion.create(map_suggestion_params).suggestion
    render json: @map_suggestion.to_json, status: :ok
  end

  def vote
    @map_suggestions = MapSuggestion.vote(map_suggestion_params, size_params)
    render json: @map_suggestions.to_json, status: :ok
  end

  private

  def map_suggestion_params
    params
      .require(:map_suggestion)
      .permit([
        :channel_id,
        :discord_player_id,
        :discord_channel_id,
        :for_teamsize
      ])
  end

  def size_params
    params
      .require(:size)
  end
end
