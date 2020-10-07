class DashboardItems
  def self.all
    {
      players: Player.all.sort_by { |player| player.trueskill_rating.skill * -1 },
      matches: Match.order('id DESC')
    }
  end
end
