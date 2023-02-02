class Players::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include Devise::Controllers::Rememberable

  # See https://github.com/omniauth/omniauth/wiki/FAQ#rails-session-is-clobbered-after-callback-on-developer-strategy
  skip_before_action :verify_authenticity_token, only: :discord

  def discord
    @player = Player.from_omniauth(request.env["omniauth.auth"])

    server_member = JSON.parse(
      Discordrb::API::Server.resolve_member(
        "Bot #{Rails.application.credentials.discord[:token]}",
        Rails.application.config.discord[:server_id],
        request.env["omniauth.auth"]["uid"]
      )
    )

    nick = server_member && server_member["nick"]
    @player.name = (nick ? nick : server_member["user"]["username"])

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
