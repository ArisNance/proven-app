class CreateCheckoutOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :checkout_orders do |t|
      t.references :user, foreign_key: true
      t.string :reference_code, null: false
      t.integer :status, null: false, default: 0
      t.string :email, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :phone
      t.string :address1, null: false
      t.string :address2
      t.string :city, null: false
      t.string :state, null: false
      t.string :postal_code, null: false
      t.string :country, null: false
      t.text :shipping_notes
      t.integer :total_cents, null: false
      t.string :currency, null: false, default: "USD"
      t.jsonb :cart_snapshot, null: false, default: []
      t.jsonb :shipstation_payload, null: false, default: {}
      t.datetime :submitted_at
      t.datetime :shipstation_submitted_at
      t.string :shipstation_order_id
      t.string :shipstation_order_number
      t.text :shipstation_error

      t.timestamps
    end

    add_index :checkout_orders, :reference_code, unique: true
    add_index :checkout_orders, :status
  end
end
