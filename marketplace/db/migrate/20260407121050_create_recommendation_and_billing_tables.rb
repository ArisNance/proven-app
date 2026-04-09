class CreateRecommendationAndBillingTables < ActiveRecord::Migration[7.1]
  def change
    create_table :recommendation_caches do |t|
      t.references :buyer, null: false, foreign_key: { to_table: :users }
      t.bigint :ranked_product_ids, array: true, null: false, default: []
      t.jsonb :payload, null: false, default: {}
      t.datetime :expires_at, null: false
      t.timestamps
    end

    add_index :recommendation_caches, :expires_at

    create_table :listing_fee_subscriptions do |t|
      t.references :shop, null: false, foreign_key: true
      t.string :stripe_subscription_id, null: false
      t.integer :status, null: false, default: 0
      t.integer :quantity, null: false, default: 1
      t.integer :unit_amount_cents, null: false, default: 15
      t.timestamps
    end

    add_index :listing_fee_subscriptions, :stripe_subscription_id, unique: true
  end
end
