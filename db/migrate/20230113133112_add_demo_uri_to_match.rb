class AddDemoUriToMatch < ActiveRecord::Migration[7.0]
  def change
    add_column :matches, :demo_uri, :string
  end
end
