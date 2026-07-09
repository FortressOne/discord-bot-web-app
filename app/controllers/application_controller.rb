class ApplicationController < ActionController::Base
  include Pagy::Backend

  def after_sign_in_path_for(resource)
    stored_location_for(resource) ||
      omniauth_origin_path ||
      if resource.is_a?(Player)
        player_url(resource)
      else
        super
      end
  end

  private

  # Signing in returns you to the page you signed in from — except the
  # home page, which sends you to your player page instead.
  def omniauth_origin_path
    origin = request.env["omniauth.origin"]
    return if origin.blank?

    uri = URI.parse(origin)
    return if uri.host.present? && uri.host != request.host
    return if uri.path.blank? || uri.path == "/"

    [uri.path, uri.query].compact.join("?")
  rescue URI::InvalidURIError
    nil
  end
end
