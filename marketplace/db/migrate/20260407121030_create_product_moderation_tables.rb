class CreateProductModerationTables < ActiveRecord::Migration[7.1]
  def change
    create_table :product_approvals do |t|
      t.bigint :product_id, null: false
      t.references :reviewer, foreign_key: { to_table: :users }
      t.integer :state, null: false, default: 0
      t.string :moderation_decision, null: false, default: "pending"
      t.float :duplicate_score, null: false, default: 0.0
      t.jsonb :policy_flags, null: false, default: []
      t.datetime :reviewed_at
      t.timestamps
    end

    add_index :product_approvals, :product_id

    create_table :flagged_items do |t|
      t.bigint :product_id, null: false
      t.integer :state, null: false, default: 0
      t.string :reason, null: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :flagged_items, :product_id
  end
end
