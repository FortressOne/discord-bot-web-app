class AddRatedToMatches < ActiveRecord::Migration[7.0]
  def change
    add_column :matches, :rated, :boolean, null: false, default: true
  end
end
