# Identity lookup for the game client's menu (avatar + display name).
# Plain-text key/value lines: QuakeC has no JSON parser.
class Api::WhoamiController < ActionController::API
  # POST /api/whoami {token} ->
  #   name <name>
  #   avatar <https url>     (line omitted when no avatar is known)
  def create
    claims = TflToken.verify(params[:token])
    return render plain: "invalid", status: :unauthorized if claims.nil?

    player = Player.find_by(id: claims[:id])
    return render plain: "invalid", status: :unauthorized if player.nil?

    lines = ["name #{player.name}"]
    lines << "avatar #{player.image}" if player.image.to_s.start_with?("https://")
    render plain: lines.join("\n")
  end
end
