class CreateWebhookEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :webhook_events do |t|
      t.string :provider, null: false
      t.string :event_id, null: false
      t.jsonb :payload, null: false, default: {}
      t.timestamps
    end

    add_index :webhook_events, %i[provider event_id], unique: true
  end
end
