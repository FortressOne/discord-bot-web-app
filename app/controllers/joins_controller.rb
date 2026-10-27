# Landing page for discord rich-presence Join/Spectate buttons.
# Existing players deep-link into the game via fortressone://; everyone
# else gets the download pitch.
class JoinsController < ApplicationController
  ADDRESS_RE = /\A[a-zA-Z0-9\-\.\:\[\]]{1,64}\z/

  def show
    @address = params[:address].to_s
    return head :bad_request unless @address.match?(ADDRESS_RE)

    @spectate = request.path.start_with?("/spectate")
  end
end
