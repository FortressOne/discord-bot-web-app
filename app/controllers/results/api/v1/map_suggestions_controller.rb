class Results::Api::V1::MapSuggestionsController < ActionController::API
  def index
    discord_channel = DiscordChannel.find_by(
      channel_id: map_suggestion_params["discord_channel_id"]
    )

    @map_suggestions = (2..6).each_with_object({}) do |teamsize, h|
      h[teamsize] = discord_channel
        .matches
        .where.not(game_map_id: nil)
        .for_teamsize(teamsize)
        .includes(:game_map)
        .last(30)
        .map { |ms| ms.game_map.name }
        .uniq
    end

    render(
      json: @map_suggestions.to_json,
      status: :ok
    )
  end

  def create
    @map_suggestion = MapSuggestion.create(map_suggestion_params).suggestion
    render json: @map_suggestion.to_json, status: :ok
  end

  def vote
    @map_suggestions = MapSuggestion.vote(map_suggestion_params)
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
end
