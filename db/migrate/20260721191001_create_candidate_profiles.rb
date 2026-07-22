class CreateCandidateProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :candidate_profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :first_name
      t.string :last_name
      t.string :phone
      t.string :email
      t.string :city
      t.string :country
      t.string :desired_job_function
      t.string :preferred_regions
      t.integer :max_travel_time
      t.string :transport_type
      t.string :search_status
      t.text :reason_for_looking
      t.string :employment_type
      t.decimal :desired_salary
      t.decimal :desired_percentage
      t.decimal :average_daily_revenue
      t.string :big_status
      t.string :big_number
      t.integer :years_of_experience
      t.string :available_days
      t.date :available_from
      t.string :notice_period
      t.text :motivation
      t.text :internal_notes
      t.text :professional_summary
      t.boolean :consent_given
      t.boolean :onboarding_completed

      t.string :cv_filled_fields, array: true, default: []

      t.timestamps
    end
  end
end
