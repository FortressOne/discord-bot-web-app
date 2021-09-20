class TwitchClient
  CLIENT_ID = Rails.application.credentials.twitch[:client_id]
  CLIENT_SECRET = Rails.application.credentials.twitch[:client_secret]
  URL = "https://id.twitch.tv/oauth2/token?client_id=#{CLIENT_ID}&client_secret=#{CLIENT_SECRET}&grant_type=client_credentials"

  def streams(game_id)
    access_token = JSON.parse(Faraday.post(URL).body)["access_token"]
    headers = {"Authorization" => "Bearer #{access_token}", "Client-Id" => CLIENT_ID}
    payload = Faraday.get("https://api.twitch.tv/helix/streams", { game_id: game_id }, headers)
    JSON.parse(payload.body)["data"].map { |stream| Stream.new(stream) }
  end
end
