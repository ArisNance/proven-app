class CreateProductFavorites < ActiveRecord::Migration[7.1]
  def change
    create_table :product_favorites do |t|
      t.references :user, null: false, foreign_key: true
      t.string :product_slug, null: false

      t.timestamps
    end

    add_index :product_favorites, [:user_id, :product_slug], unique: true
    add_index :product_favorites, :product_slug
  end
end
