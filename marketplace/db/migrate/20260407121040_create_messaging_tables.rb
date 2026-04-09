class CreateMessagingTables < ActiveRecord::Migration[7.1]
  def change
    create_table :conversations do |t|
      t.references :buyer, null: false, foreign_key: { to_table: :users }
      t.references :maker, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end

    add_index :conversations, %i[buyer_id maker_id], unique: true

    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.text :body, null: false
      t.timestamps
    end
  end
end
