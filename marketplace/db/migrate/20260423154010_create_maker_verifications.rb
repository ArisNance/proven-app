class CreateMakerVerifications < ActiveRecord::Migration[7.1]
  def change
    create_table :maker_verifications do |t|
      t.references :maker_application, null: false, foreign_key: true, index: { unique: true }
      t.references :verified_by, foreign_key: { to_table: :users }

      t.integer :identity_status, null: false, default: 0
      t.integer :workspace_status, null: false, default: 0
      t.integer :production_capability_status, null: false, default: 0
      t.integer :product_origin_status, null: false, default: 0

      t.string :identity_name_given
      t.boolean :identity_id_verified
      t.integer :identity_name_match_confidence
      t.text :identity_notes

      t.integer :workspace_type
      t.integer :workspace_confidence
      t.text :workspace_notes

      t.boolean :production_in_progress_product_seen
      t.boolean :production_process_explained
      t.boolean :production_materials_observed
      t.integer :production_complexity_level
      t.integer :production_confidence
      t.text :production_notes

      t.boolean :product_origin_matched_to_maker
      t.boolean :product_origin_categories_verified
      t.boolean :product_origin_inconsistencies_flagged
      t.integer :product_origin_confidence
      t.text :product_origin_notes

      t.boolean :red_flag_stock_like_imagery, null: false, default: false
      t.boolean :red_flag_inconsistent_story, null: false, default: false
      t.boolean :red_flag_no_in_progress_proof, null: false, default: false
      t.boolean :red_flag_unclear_production_chain, null: false, default: false

      t.integer :maker_type_classification
      t.integer :overall_confidence_score
      t.integer :verification_method
      t.integer :verification_duration_minutes
      t.datetime :verified_on
      t.text :reviewer_notes

      t.timestamps
    end
  end
end

