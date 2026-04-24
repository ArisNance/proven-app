class EnforceSingleShopPerMaker < ActiveRecord::Migration[7.1]
  def change
    remove_index :shops, :maker_id if index_exists?(:shops, :maker_id)
    add_index :shops, :maker_id, unique: true
  end
end
