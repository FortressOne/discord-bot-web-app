# Mints a TFL login token for a Discord user, on behalf of the Discord bot's
# /token command. Authenticated with a shared bearer token so only the bot can
# mint tokens for arbitrary Discord ids.
class Api::TokensController < ActionController::API
  def create
    return head :unauthorized unless bot_authorized?
    return head :bad_request if params[:discord_id].blank?

    player = Player.find_by(discord_id: params[:discord_id])

    if player.nil?
      return head :unprocessable_entity if params[:name].blank?

      player = Player.create!(discord_id: params[:discord_id], name: params[:name])
    end

    render json: { token: TflToken.mint(player), name: player.name }
  end

  private

  def bot_authorized?
    expected = ENV["BOT_API_TOKEN"]
    supplied = request.headers["Authorization"].to_s.delete_prefix("Bearer ")

    expected.present? &&
      ActiveSupport::SecurityUtils.secure_compare(supplied, expected)
  end
end
