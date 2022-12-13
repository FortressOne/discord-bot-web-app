class AddRememberTokenToPlayer < ActiveRecord::Migration[7.0]
  def change
    add_column :players, :remember_token, :string
  end
end
