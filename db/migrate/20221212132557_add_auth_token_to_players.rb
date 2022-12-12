class AddAuthTokenToPlayers < ActiveRecord::Migration[7.0]
  def change
    add_column :players, :auth_token, :string
    add_index :players, :auth_token, unique: true
  end
end
