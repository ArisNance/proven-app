class AddProcessingFieldsToWebhookEvents < ActiveRecord::Migration[7.1]
  def change
    add_column :webhook_events, :event_type, :string
    add_column :webhook_events, :processed_at, :datetime
    add_column :webhook_events, :processing_error, :text

    add_index :webhook_events, :event_type
    add_index :webhook_events, :processed_at
  end
end

