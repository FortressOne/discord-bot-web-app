# Shared-secret bearer auth for endpoints that only the Discord bot may call.
module BotAuthentication
  extend ActiveSupport::Concern

  private

  def bot_authorized?
    expected = ENV["BOT_API_TOKEN"]
    supplied = request.headers["Authorization"].to_s.delete_prefix("Bearer ")

    expected.present? &&
      ActiveSupport::SecurityUtils.secure_compare(supplied, expected)
  end

  def require_bot_token
    head :unauthorized unless bot_authorized?
  end
end
