# Rejects oversized request bodies on the in-game API (/api/*) with a 413
# before Rails parses them: params parsing (parameter wrapping, request
# logging) happens before any controller code runs. The largest legitimate
# body is a match report: ~150 bytes per player, a few KB per game.
class ApiBodyLimit
  PATH_PREFIX = "/api/".freeze
  MAX_BYTES = 64 * 1024

  def initialize(app)
    @app = app
  end

  def call(env)
    if env["PATH_INFO"].to_s.start_with?(PATH_PREFIX) && env["CONTENT_LENGTH"].to_i > MAX_BYTES
      [413, { "content-type" => "text/plain" }, ["Payload Too Large"]]
    else
      @app.call(env)
    end
  end
end
