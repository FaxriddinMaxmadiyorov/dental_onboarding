class CreateCandidateDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :candidate_documents do |t|
      t.references :candidate_profile, null: false, foreign_key: true
      t.string :document_type
      t.string :original_filename
      t.string :content_type
      t.integer :file_size
      t.datetime :parsed_at
      t.integer :parsing_status
      t.jsonb :parsed_data

      t.timestamps
    end
  end
end
