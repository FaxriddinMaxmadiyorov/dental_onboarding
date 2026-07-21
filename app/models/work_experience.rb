class WorkExperience < ApplicationRecord
  belongs_to :candidate_profile
  validates :job_title, :company_name, presence: true
end
