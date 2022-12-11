class AddImageToPlayers < ActiveRecord::Migration[7.0]
  def change
    add_column :players, :image, :string
  end
end
