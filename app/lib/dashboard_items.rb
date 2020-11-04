class DashboardItems
  def self.all
    {
      players: Player.leaderboard,
      matches: Match.order('id DESC')
    }
  end
end
