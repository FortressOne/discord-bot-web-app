class SitemapsController < ApplicationController
  HOST = ApplicationHelper::CANONICAL_HOST
  STATIC_PATHS = ["/", "/stats", "/matches", "/players", "/code-of-conduct"].freeze

  # ~18k URLs today, well under the 50k single-sitemap limit. Per-match
  # result pages are left out on purpose: they are thin score-only
  # duplicates of the rich per-match stats pages.
  def show
    xml = Rails.cache.fetch("sitemap-xml", expires_in: 12.hours) { build }
    render xml: xml
  end

  private

  def build
    entries = STATIC_PATHS.map { |path| entry(path, nil) }
    entries += MatchStat.parsed.order(:id).pluck(:id, :updated_at).map { |id, at| entry("/stats/#{id}", at) }
    entries += Player.order(:id).pluck(:id, :updated_at).map { |id, at| entry("/players/#{id}", at) }

    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
      #{entries.join("\n")}
      </urlset>
    XML
  end

  def entry(path, updated_at)
    lastmod = updated_at ? "<lastmod>#{updated_at.strftime('%Y-%m-%d')}</lastmod>" : ""
    "<url><loc>#{HOST}#{path == '/' ? '/' : path}</loc>#{lastmod}</url>"
  end
end
