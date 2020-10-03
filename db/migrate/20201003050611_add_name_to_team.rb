class AddNameToTeam < ActiveRecord::Migration[6.0]
  def change
    add_column :teams, :number, :string
  end
end
