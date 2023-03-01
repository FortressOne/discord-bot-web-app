class Players::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include Devise::Controllers::Rememberable

  # See https://github.com/omniauth/omniauth/wiki/FAQ#rails-session-is-clobbered-after-callback-on-developer-strategy
  skip_before_action :verify_authenticity_token, only: :discord

  def discord
    @player = Player.from_omniauth(request.env["omniauth.auth"])

    fo_discord_server_member = Discordrb::API::Server.resolve_member(
      "Bot #{Rails.application.credentials.discord[:token]}",
      Rails.application.config.discord[:server_id],
      request.env["omniauth.auth"]["uid"]
    )

    if fo_discord_server_member
      json = JSON.parse(fo_discord_server_member)

      name = if json["nick"]
               json["nick"]
             else
               json["user"]["username"]
             end

      @player.update(name: name)
    end

    if @player.persisted?
      remember_me(@player)
      sign_in_and_redirect @player, event: :authentication # this will throw if @player is not activated
      set_flash_message(:notice, :success, kind: "discord") if is_navigational_format?
    else
      session["devise.discord_data"] = request.env["omniauth.auth"].except(:extra) # Removing extra as it can overflow some session stores
      redirect_to new_player_registration_url
    end
  end

  def failure
    redirect_to root_path
  end
end
