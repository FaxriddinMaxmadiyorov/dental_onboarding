class CreateCandidateLanguages < ActiveRecord::Migration[8.1]
  def change
    create_table :candidate_languages do |t|
      t.references :candidate_profile, null: false, foreign_key: true
      t.references :language, null: false, foreign_key: true
      t.string :level

      t.timestamps
    end
  end
end
