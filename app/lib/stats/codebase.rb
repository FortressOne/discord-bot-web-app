# Commit and contributor totals for the server-qwprogs repo — the codebase's
# whole history since Classic Fortress imported Team Fortress 2.9 in 2014.
# Read from the GitHub API's pagination headers (per_page=1 makes the last
# page number the total), so no clone or token is needed.
module Stats
  class Codebase
    REPO = "FortressOne/server-qwprogs".freeze

    def self.metrics
      Rails.cache.read("codebase-metrics") || fetch_and_cache
    end

    def self.fetch_and_cache
      metrics = {
        commits: last_page("commits?per_page=1"),
        contributors: last_page("contributors?per_page=1&anon=1")
      }
      Rails.cache.write("codebase-metrics", metrics, expires_in: 24.hours)
      metrics
    rescue StandardError
      nil
    end

    def self.last_page(path)
      response = Faraday.head("https://api.github.com/repos/#{REPO}/#{path}")
      raise "GitHub request failed (#{response.status})" unless response.success?

      match = response.headers["link"]&.match(/[?&]page=(\d+)>; rel="last"/)
      raise "no pagination in GitHub response" unless match

      match[1].to_i
    end
  end
end
