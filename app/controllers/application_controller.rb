class ApplicationController < ActionController::Base
  include Pagy::Backend

  # ?page=0, ?page=abc or a page past the end: 404 instead of a 500.
  # (OverflowError is a VariableError.)
  rescue_from Pagy::VariableError, with: :page_not_found

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

  def page_not_found
    respond_to do |format|
      format.html { render file: Rails.public_path.join("404.html"), status: :not_found, layout: false }
      format.any { head :not_found }
    end
  end

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
