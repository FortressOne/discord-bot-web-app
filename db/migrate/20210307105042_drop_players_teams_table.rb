class DropPlayersTeamsTable < ActiveRecord::Migration[6.0]
  def change
    drop_table :players_teams
  end
end
