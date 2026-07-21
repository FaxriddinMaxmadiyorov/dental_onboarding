class CreateCandidateSkills < ActiveRecord::Migration[8.1]
  def change
    create_table :candidate_skills do |t|
      t.references :candidate_profile, null: false, foreign_key: true
      t.references :skill, null: false, foreign_key: true
      t.string :free_text_suggestion

      t.timestamps
    end
  end
end
