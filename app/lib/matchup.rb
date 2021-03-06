class Matchup
  def initialize(teams)
    @team1_players = teams.keys[0].map do |i|
      i.player.discord_id.to_i.to_s
    end

    @team2_players = teams.keys[1].map do |i|
      i.player.discord_id.to_i.to_s
    end

    @team1_score, @team2_score = *teams.values
  end

  def difference
    (@team1_score - @team2_score).abs
  end

  def teams
    { 1 => @team1_players, 2 => @team2_players }
  end
end
