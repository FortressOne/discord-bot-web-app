class ApplicationController < ActionController::Base
  include Pagy::Backend

  before_action :log_request_format

  def after_sign_in_path_for(resource)
    stored_location_for(resource) ||
      if resource.is_a?(Player)
        player_url(resource)
      else
        super
      end
  end

  private

  def log_request_format
    Rails.logger.info("Headers: #{request.headers.to_h}")
    Rails.logger.info("Request format: #{request.format}")
    Rails.logger.info("Parameters: #{params.to_unsafe_h}")
    Rails.logger.info("User Agent: #{request.user_agent}")
  end
end
