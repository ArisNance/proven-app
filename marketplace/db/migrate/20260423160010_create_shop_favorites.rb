class CreateShopFavorites < ActiveRecord::Migration[7.1]
  def change
    create_table :shop_favorites do |t|
      t.references :user, null: false, foreign_key: true
      t.references :shop, null: false, foreign_key: true

      t.timestamps
    end

    add_index :shop_favorites, [:user_id, :shop_id], unique: true
  end
end
