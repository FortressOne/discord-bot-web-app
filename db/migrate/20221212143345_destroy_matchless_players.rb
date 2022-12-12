class DestroyMatchlessPlayers < ActiveRecord::Migration[7.0]
  def change
    Player.where(name: nil).destroy_all
  end
end
