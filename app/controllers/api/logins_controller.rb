# Login endpoint for QWTF-Live progs (ssqc/json.qc WEB_MigrateLoginRequest and
# WEB_CheckLoginRequest). The progs POST JSON and expect the bare token string
# back in the response body; any non-2xx response is treated as login failure.
class Api::LoginsController < ActionController::API
  def create
    case params[:type]
    when "migrate"
      migrate
    when "check"
      check
    else
      head :bad_request
    end
  end

  private

  # { type: "migrate", fo_login: <name>, fo_token: <legacy auth_token> }
  def migrate
    player = params[:fo_token].present? && Player.find_by(auth_token: params[:fo_token])

    if player
      render plain: TflToken.mint(player)
    else
      head :forbidden
    end
  end

  # { type: "check", token: <tfl token> } — re-mint from current player state
  # so renames produce a fresh token.
  def check
    payload = TflToken.verify(params[:token])
    player = payload && Player.find_by(id: payload[:foid])

    if player
      render plain: TflToken.mint(player)
    else
      head :forbidden
    end
  end
end
