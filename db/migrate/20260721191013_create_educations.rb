class CreateEducations < ActiveRecord::Migration[8.1]
  def change
    create_table :educations do |t|
      t.references :candidate_profile, null: false, foreign_key: true
      t.string :institution
      t.string :study
      t.string :city_country
      t.string :level
      t.date :start_date
      t.date :end_date
      t.boolean :from_cv

      t.timestamps
    end
  end
end
