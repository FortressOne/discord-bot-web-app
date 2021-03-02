class AddInvisibleToPlayer < ActiveRecord::Migration[6.0]
  def change
    add_column :players, :invisible, :bool, null: false, default: false
  end
end
