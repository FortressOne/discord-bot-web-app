class CreateTeamsPlayers < ActiveRecord::Migration[6.0]
  def change
    create_join_table :teams, :players
  end
end
