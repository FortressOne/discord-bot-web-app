class AddNameToTeam < ActiveRecord::Migration[6.0]
  def change
    add_column :teams, :name, :string
  end
end
