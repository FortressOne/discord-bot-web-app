namespace :stats do
  desc "Backfill match stats from the fortressone-stats S3 bucket. " \
       "Optional: PREFIX=sydney/pub/ LIMIT=100 FORCE=1"
  task backfill: :environment do
    prefix = ENV["PREFIX"].presence
    limit = ENV["LIMIT"].presence&.to_i
    force = ENV["FORCE"].present?

    existing_keys = force ? Set.new : MatchStat.pluck(:s3_key).to_set
    counts = Hash.new(0)
    imported = 0

    Stats::Archive.each_key(prefix: prefix) do |key|
      next if existing_keys.include?(key)

      match_stat = Stats::Importer.import_key(key, force: force)
      counts[match_stat.status] += 1
      imported += 1
      puts "[#{imported}] #{match_stat.status.ljust(6)} #{key}" if (imported % 100).zero? || match_stat.status == "error"
      break if limit && imported >= limit
    rescue StandardError => e
      counts["failed"] += 1
      warn "FAILED #{key}: #{e.class}: #{e.message}"
    end

    puts "Done. #{imported} imported: #{counts.map { |status, count| "#{status}=#{count}" }.join(', ')}"
  end

  desc "Import a single match log by S3 key, e.g. stats:import[sydney/pub/2022-....json]"
  task :import, [:key] => :environment do |_, args|
    match_stat = Stats::Importer.import_key(args[:key], force: true)
    puts "#{match_stat.status}: #{match_stat.s3_key} (#{match_stat.player_match_stats.count} players)"
    puts match_stat.error_message if match_stat.error_message.present?
  end

  desc "Retry match logs that previously failed to import"
  task retry_errors: :environment do
    MatchStat.where(status: %w[pending error]).find_each do |match_stat|
      result = Stats::Importer.import_key(match_stat.s3_key, force: true)
      puts "#{result.status}: #{result.s3_key}"
    rescue StandardError => e
      warn "FAILED #{match_stat.s3_key}: #{e.message}"
    end
  end

  desc "Link parsed match stats to Match records via demo filename"
  task link_matches: :environment do
    linked = 0
    MatchStat.where(match_id: nil).where.not(demo_filename: nil).find_each do |match_stat|
      match = Match.where("demo_uri LIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(match_stat.demo_filename)}").first
      next unless match

      match_stat.update!(match: match)
      linked += 1
    end
    puts "Linked #{linked} match stats to matches."
  end
end
