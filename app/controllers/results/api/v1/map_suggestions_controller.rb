class Results::Api::V1::MapSuggestionsController < ActionController::API
  include BotAuthentication

  # Only the pickup bot's !map, !maps and vote commands call these
  # (qwtf-discord-bot qwtf_discord_bot_vote.rb). It sends the same bearer
  # token as /api/token.
  before_action :require_bot_token

  RECENT_MAP_COUNT = 50
  # The bot asks for 3 minus however many maps players suggested.
  MAX_VOTE_SIZE = 5

  def index
    json = MapSuggestion
      .index(channel_id: map_suggestion_params["discord_channel_id"])
      .to_json

    render(json: json, status: :ok)
  end

  def create
    @map_suggestion = MapSuggestion.create(map_suggestion_params).suggestion
    render json: @map_suggestion.to_json, status: :ok
  end

  def vote
    map_suggestions = MapSuggestion.vote(
      attributes: map_suggestion_params,
      size: vote_size,
      except: Array(params[:except]).grep(String).first(MAX_VOTE_SIZE * 2)
    )

    render json: map_suggestions.to_json, status: :ok
  end

  private

  # Each unit of size creates a MapSuggestion row.
  def vote_size
    params.fetch(:size, 3).to_s.to_i.clamp(1, MAX_VOTE_SIZE)
  end

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
