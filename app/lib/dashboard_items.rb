class DashboardItems
  def self.all
    {
      players: Player.leaderboard,
      matches: Match.history
    }
  end
end
