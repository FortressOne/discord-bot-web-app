# Imports one match log from the fortressone-stats bucket into MatchStat +
# PlayerMatchStat rows, linking to an existing Match where the demo filename
# lines up.
module Stats
  class Importer
    KEY_PATTERN = %r{\A(?<region>[^/]+)/(?<game_mode>[^/]+)/(?<filename>[^/]+)\.json\z}

    def self.import_key(s3_key, force: false, linker: nil)
      new(s3_key, linker: linker).import(force: force)
    end

    def initialize(s3_key, archive: Archive.new, linker: nil)
      @s3_key = s3_key
      @archive = archive
      @linker = linker || PlayerLinker.new
    end

    def import(force: false)
      existing = MatchStat.find_by(s3_key: @s3_key)
      return existing if existing && !force

      result = Stats::EventLogParser.parse(@archive.fetch(@s3_key))
      persist(existing, result)
    end

    private

    def persist(existing, result)
      key_parts = @s3_key.match(KEY_PATTERN)
      match_stat = existing || MatchStat.new(s3_key: @s3_key)

      MatchStat.transaction do
        match_stat.assign_attributes(
          region: key_parts&.[](:region),
          game_mode: key_parts&.[](:game_mode),
          map_name: result.map_name.presence || map_name_from_key(key_parts),
          played_at: result.played_at || played_at_from_key(key_parts),
          duration_seconds: result.duration_seconds,
          team1_name: result.team1_name,
          team2_name: result.team2_name,
          team1_score: result.team1_score,
          team2_score: result.team2_score,
          winning_team: result.winning_team,
          player_count: result.player_count,
          demo_filename: result.demo_filename,
          status: result.status,
          error_message: result.error_message,
          match: linked_match(result)
        )
        match_stat.save!

        match_stat.player_match_stats.delete_all
        result.players.each do |name, stats|
          match_stat.player_match_stats.create!(name: name, player_id: @linker.player_id_for(name), **stats)
        end
      end

      match_stat
    end

    def linked_match(result)
      return nil if result.demo_filename.blank?

      Match.where("demo_uri LIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(result.demo_filename)}").first
    end

    def map_name_from_key(key_parts)
      key_parts && key_parts[:filename][/\[([^\]]+)\]/, 1]
    end

    def played_at_from_key(key_parts)
      return nil unless key_parts

      timestamp = key_parts[:filename][/\A\d{4}-\d{2}-\d{2}[_-]\d{2}-\d{2}-\d{2}/]
      return nil unless timestamp

      Time.utc(*timestamp.scan(/\d+/).map(&:to_i))
    rescue ArgumentError
      nil
    end
  end
end
