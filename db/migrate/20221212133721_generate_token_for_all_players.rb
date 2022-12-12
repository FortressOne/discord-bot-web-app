class GenerateTokenForAllPlayers < ActiveRecord::Migration[7.0]
  def change
    Player.find_each do |player|
      player.get_auth_token
    end
  end
end
