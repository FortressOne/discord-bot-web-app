class LivePlayerController < ApplicationController
  CLIENT_ID = "6th9ri0ta837yw7o5erw7zpuptj6nx"
  CLIENT_SECRET = "kdt2efelht5s8um90latu8qzqxsgps"
  FORTRESSONE_GAME_ID = 1973310673
  URL = "https://id.twitch.tv/oauth2/token?client_id=#{CLIENT_ID}&client_secret=#{CLIENT_SECRET}&grant_type=client_credentials"

  def show
    access_token = JSON.parse(Faraday.post(URL).body)["access_token"]
    headers = {"Authorization" => "Bearer #{access_token}", "Client-Id" => CLIENT_ID}
    payload = Faraday.get("https://api.twitch.tv/helix/streams", { game_id: FORTRESSONE_GAME_ID }, headers)
    body = JSON.parse(payload.body)["data"]

    if body.empty?
      render(status: 404) && return
    end

    @channel = body.first["user_name"]
  end
end
