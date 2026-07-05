# Splits a match's per-player half stats into role tables and pairs
# same-class opponents for head-to-head comparison.
#
# In the pug convention team 1 attacks the first half and team 2 the second
# (see EventLogParser#attack_defence?), so a player's attacking half is the
# one matching their team number. Matches that don't follow the convention
# (symmetric maps, pubs) fall back to plain first/second-half tables.
module Stats
  class HalfBreakdown
    # A player's stats for one half. Quacks like PlayerMatchStat where the
    # stats views need it (stats_player_link, stats_class_icons).
    Row = Struct.new(
      :name, :player_id, :team, :half,
      :kills, :deaths, :teamkills, :suicides, :sentries_destroyed,
      :damage_given, :damage_taken, :team_damage,
      :flag_touches, :flag_caps, :flag_drops, :flag_throws, :flag_stops,
      :flag_carry_seconds, :class_seconds,
      keyword_init: true
    ) do
      def kd_ratio
        return kills.to_f if deaths.zero?

        (kills / deaths.to_f).round(2)
      end

      def flag_carry_display
        format("%d:%02d", flag_carry_seconds / 60, flag_carry_seconds % 60)
      end

      def dominant_class
        class_seconds.max_by { |_, seconds| seconds }&.first
      end
    end

    Matchup = Struct.new(:role, :class_name, :left, :right, :duels, keyword_init: true)

    # Only players present for at least half of a half get a row in its
    # table (fo-stats uses an even stricter cutoff).
    MIN_PRESENCE = 0.5

    def initialize(match_stat, players)
      @match_stat = match_stat
      @players = players
      duration = match_stat.duration_seconds.to_i
      boundary = match_stat.half_boundary_seconds || duration / 2
      @half_lengths = { 1 => boundary, 2 => duration - boundary }
    end

    def attack_defence?
      @match_stat.attack_defence
    end

    # When the match ends early (team 2 passing team 1's score wins on the
    # spot) one half is shorter; its stats scale up by this factor for a
    # fair comparison. 1 for full-length halves.
    def half_weight(half)
      own = @half_lengths[half].to_i
      other = @half_lengths[3 - half].to_i
      return 1 unless own.positive? && other > own

      other.fdiv(own)
    end

    def weighted?
      attack_defence? && [1, 2].any? { |half| half_weight(half) > 1.01 }
    end

    def ended_early_display
      seconds = (@half_lengths[1] - @half_lengths[2]).abs
      ["#{seconds / 60}m", "#{seconds % 60}s"].select { |part| part =~ /[1-9]/ }.join(" ")
    end

    def weight_percent
      (([half_weight(1), half_weight(2)].max - 1) * 100).round
    end

    def any?
      tables.values.any?(&:any?)
    end

    # {attack:, defence:} when the match follows the pug convention,
    # {first_half:, second_half:} otherwise. Attackers rank by caps,
    # defenders by kills, both across teams.
    def tables
      @tables ||= if attack_defence?
        { attack: rows.select { |row| row.half == row.team }
                      .sort_by { |row| [-row.flag_caps, -row.kills] },
          defence: rows.reject { |row| row.half == row.team }
                       .sort_by { |row| [-row.kills, -row.damage_given] } }
      else
        { first_half: rows.select { |row| row.half == 1 },
          second_half: rows.select { |row| row.half == 2 } }
          .transform_values { |list| list.sort_by { |row| [row.team, -row.kills] } }
      end
    end

    # One head-to-head per role and class when exactly one player per team
    # played it (i.e. highlander-style matches). Left is always team 1.
    def matchups
      return [] unless attack_defence?

      @matchups ||= tables.flat_map do |role, role_rows|
        role_rows.group_by(&:dominant_class).filter_map do |class_name, pair|
          next unless class_name && pair.size == 2

          left, right = pair.sort_by(&:team)
          next if left.team == right.team

          Matchup.new(role: role, class_name: class_name, left: left, right: right,
                      duels: duels_between(left.name, right.name))
        end
      end
    end

    private

    def rows
      @rows ||= @players.flat_map do |player|
        player.half_stats.filter_map do |half, stats|
          class_seconds = stats["class_seconds"] || {}
          half_length = @half_lengths[half.to_i].to_i
          next if half_length.positive? && class_seconds.values.sum < half_length * MIN_PRESENCE

          Row.new(
            name: player.name, player_id: player.player_id,
            team: stats["team"] || player.team, half: half.to_i,
            kills: stats["kills"].to_i, deaths: stats["deaths"].to_i,
            teamkills: stats["teamkills"].to_i, suicides: stats["suicides"].to_i,
            sentries_destroyed: stats["sentries_destroyed"].to_i,
            damage_given: stats["damage_given"].to_i, damage_taken: stats["damage_taken"].to_i,
            team_damage: stats["team_damage"].to_i,
            flag_touches: stats["flag_touches"].to_i, flag_caps: stats["flag_caps"].to_i,
            flag_drops: stats["flag_drops"].to_i, flag_throws: stats["flag_throws"].to_i,
            flag_stops: stats["flag_stops"].to_i,
            flag_carry_seconds: stats["flag_carry_seconds"].to_i,
            class_seconds: class_seconds
          )
        end
      end
    end

    def duels_between(left, right)
      matrix = @match_stat.kill_matrix
      {
        left_kills: matrix.dig(left, right, "kills").to_i,
        right_kills: matrix.dig(right, left, "kills").to_i,
        left_damage: matrix.dig(left, right, "damage").to_i,
        right_damage: matrix.dig(right, left, "damage").to_i
      }
    end
  end
end
