class AddUsernameToShops < ActiveRecord::Migration[7.1]
  def change
    add_column :shops, :username, :string
    add_index :shops, :username, unique: true
  end
end

