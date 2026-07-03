# The browser half of the in-game device-pairing flow: the player lands here
# with the code the game menu showed them, signs in with Discord if needed,
# and explicitly approves releasing a login token to that game client.
class LinksController < ApplicationController
  def show
    @code = params[:code]
    # So the Discord OAuth round-trip comes back to this page, code intact.
    store_location_for(:player, link_path(code: @code)) unless player_signed_in?
  end

  def create
    return redirect_to link_path(code: params[:code]) unless player_signed_in?

    device_code = DeviceCode.find_active(params[:code])
    if device_code&.approve(current_player)
      render :approved
    else
      redirect_to link_path(code: params[:code]),
                  alert: "That code isn't valid any more — get a fresh one from the game menu."
    end
  end
end
