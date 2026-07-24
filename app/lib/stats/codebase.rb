# Commit and contributor totals for FortressOne's code: server-qwprogs
# (whose history begins at Classic Fortress's Team Fortress import in 2014),
# the discord bot, the map repo and this website. Read from the GitHub API
# with no token or clone — per_page=1 makes the Link header's last page
# number the commit total, and contributor identities are deduped across
# repos.
module Stats
  class Codebase
    REPOS = %w[
      FortressOne/server-qwprogs
      FortressOne/qwtf-discord-bot
      FortressOne/map-repo
      FortressOne/discord-bot-web-app
    ].freeze

    # Anonymous (email-only) contributors who also appear under a GitHub
    # login, so they aren't counted twice.
    ALIASES = {
      "sheldon johnson" => "drzel",
      "sheldon@sheldon-desktop.lan" => "drzel",
      "root@desktop.localdomain" => "drzel",
      "newby@rakis.net" => "newbytf",
      "driz@drizspamcollector.com" => "driztf"
    }.freeze

    def self.metrics
      Rails.cache.read("codebase-metrics") || fetch_and_cache
    end

    def self.fetch_and_cache
      metrics = {
        commits: REPOS.sum { |repo| commit_count(repo) },
        contributors: REPOS.flat_map { |repo| contributor_keys(repo) }.uniq.size
      }
      Rails.cache.write("codebase-metrics", metrics, expires_in: 24.hours)
      metrics
    rescue StandardError
      nil
    end

    def self.commit_count(repo)
      response = Faraday.head("https://api.github.com/repos/#{repo}/commits?per_page=1")
      raise "GitHub request failed (#{response.status})" unless response.success?

      match = response.headers["link"]&.match(/[?&]page=(\d+)>; rel="last"/)
      raise "no pagination in GitHub response" unless match

      match[1].to_i
    end

    def self.contributor_keys(repo)
      response = Faraday.get("https://api.github.com/repos/#{repo}/contributors?per_page=100&anon=1")
      raise "GitHub request failed (#{response.status})" unless response.success?

      JSON.parse(response.body).filter_map do |contributor|
        key = contributor["login"] || contributor["email"]
        next if key.nil? || key.end_with?("[bot]")

        ALIASES.fetch(key, key)
      end
    end
  end
end
