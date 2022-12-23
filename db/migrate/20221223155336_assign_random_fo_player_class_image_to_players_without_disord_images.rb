class AssignRandomFoPlayerClassImageToPlayersWithoutDisordImages < ActiveRecord::Migration[7.0]
  def up
    Player.where(image: nil).each do |player|
      player.update(image: "home/classes/#{Player::IMAGES.sample}")
    end
  end

  def down
    Player.where("image like ?", "home/classes/%").each do |player|
      player.update(image: nil)
    end
  end
end
