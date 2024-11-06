# app/middleware/redirect_to_www.rb
class RedirectToWww
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    # Check if request domain is not prefixed with 'www'
    if request.host == "fortressone.org"
      # Perform 301 redirect to the www version
      [301, { "Location" => "https://www.fortressone.org#{request.fullpath}" }, []]
    else
      @app.call(env)
    end
  end
end
