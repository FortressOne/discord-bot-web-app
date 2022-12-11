class AddPublicRatingsToPlayer < ActiveRecord::Migration[7.0]
  def change
    add_column :players, :public_ratings, :boolean
  end
end
