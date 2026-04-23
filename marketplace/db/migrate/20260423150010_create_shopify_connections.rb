class CreateShopifyConnections < ActiveRecord::Migration[7.1]
  def change
    create_table :shopify_connections do |t|
      t.references :user, null: false, foreign_key: true
      t.string :shop_domain, null: false
      t.text :access_token, null: false
      t.string :scopes, null: false, default: ""
      t.integer :status, null: false, default: 0
      t.datetime :installed_at
      t.datetime :last_synced_at
      t.string :last_sync_status
      t.text :last_sync_error

      t.timestamps
    end

    add_index :shopify_connections, :shop_domain, unique: true
  end
end

