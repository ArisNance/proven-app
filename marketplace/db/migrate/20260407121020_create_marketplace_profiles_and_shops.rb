class CreateMarketplaceProfilesAndShops < ActiveRecord::Migration[7.1]
  def change
    create_table :maker_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :display_name, null: false
      t.text :bio
      t.string :country, null: false
      t.string :preferred_currency, default: "USD"
      t.string :stripe_account_id
      t.timestamps
    end

    create_table :buyer_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.text :preference_tags
      t.timestamps
    end

    create_table :shops do |t|
      t.references :maker, null: false, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.text :description
      t.integer :state, null: false, default: 0
      t.string :stripe_customer_id
      t.timestamps
    end

    create_table :shop_approvals do |t|
      t.references :shop, null: false, foreign_key: true
      t.references :reviewer, foreign_key: { to_table: :users }
      t.integer :state, null: false, default: 0
      t.datetime :reviewed_at
      t.timestamps
    end
  end
end
