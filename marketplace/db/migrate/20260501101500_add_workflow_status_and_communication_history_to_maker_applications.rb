class AddWorkflowStatusAndCommunicationHistoryToMakerApplications < ActiveRecord::Migration[7.1]
  def change
    add_column :maker_applications, :workflow_status, :string
    add_column :maker_applications, :communication_history, :jsonb, default: [], null: false

    add_index :maker_applications, :workflow_status
  end
end
