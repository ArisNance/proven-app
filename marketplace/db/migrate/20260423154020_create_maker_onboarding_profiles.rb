class CreateMakerOnboardingProfiles < ActiveRecord::Migration[7.1]
  def change
    create_table :maker_onboarding_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.references :maker_application, foreign_key: true
      t.references :shop, foreign_key: true
      t.integer :state, null: false, default: 0

      t.string :legal_first_name, null: false
      t.string :legal_last_name, null: false
      t.string :legal_business_name, null: false
      t.string :tax_identifier, null: false
      t.string :dba_business_name, null: false
      t.string :username, null: false
      t.string :year_started
      t.string :main_product_category, null: false

      t.text :what_do_you_make_and_started
      t.text :what_inspires_your_work
      t.text :favorite_part_of_process
      t.text :favorite_product_to_make
      t.text :what_you_listen_to
      t.text :what_makes_work_different
      t.text :time_to_create_one_piece
      t.text :workspace_typical_day
      t.text :what_people_should_know
      t.text :what_to_watch_in_process

      t.string :lead_time_for_fulfillment, null: false
      t.text :shipping_policy, null: false
      t.boolean :returns_accepted, null: false
      t.boolean :exchanges_accepted, null: false
      t.boolean :refunds_accepted, null: false
      t.text :additional_policy_information
      t.boolean :cancellations_accepted, null: false
      t.text :cancellation_timeframe
      t.text :privacy_policy, null: false
      t.text :maker_faq

      t.timestamps
    end

    add_index :maker_onboarding_profiles, :username, unique: true
  end
end

