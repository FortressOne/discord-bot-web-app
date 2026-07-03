# Device-pairing flow for in-game Discord sign-in (see server-qwprogs menu/).
# Responses are plain text because the consumer is QuakeC with no JSON parser.
class Api::DevicesController < ActionController::API
  # POST /api/device -> "ABCD-1234"
  def create
    render plain: DeviceCode.mint.code
  end

  # GET /api/device/:code -> "pending" | "token <tfl token>" | "expired"
  def show
    device_code = DeviceCode.find_active(params[:code])
    return render plain: "expired" if device_code.nil?

    case device_code.status
    when "pending"
      render plain: "pending"
    when "approved"
      token = device_code.claim!
      render plain: token ? "token #{token}" : "expired"
    else
      render plain: "expired"
    end
  end
end
