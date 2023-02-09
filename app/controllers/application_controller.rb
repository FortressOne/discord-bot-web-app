class ApplicationController < ActionController::Base
  include Pagy::Backend

  def after_sign_in_path_for(resource)
    stored_location_for(resource) ||
      if resource.is_a?(Player)
        player_url(resource)
      else
        super
      end
  end
end
