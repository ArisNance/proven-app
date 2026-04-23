class CreateMakerApplications < ActiveRecord::Migration[7.1]
  def change
    create_table :maker_applications do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.references :reviewer, foreign_key: { to_table: :users }
      t.integer :state, null: false, default: 0

      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false
      t.string :business_name, null: false
      t.string :business_url, null: false
      t.string :what_do_you_make, null: false
      t.string :how_long_making

      t.datetime :submitted_at
      t.datetime :reviewed_at
      t.text :admin_notes
      t.timestamps
    end

    add_index :maker_applications, :state
  end
end

