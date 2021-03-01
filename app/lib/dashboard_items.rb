class DashboardItems
  def self.all
    {
      players: Player.global_leaderboard,
      matches: Match.history
    }
  end
end
