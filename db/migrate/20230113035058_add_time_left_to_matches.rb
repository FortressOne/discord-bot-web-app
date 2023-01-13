class AddTimeLeftToMatches < ActiveRecord::Migration[7.0]
  def change
    add_column :matches, :time_left, :integer
  end
end
