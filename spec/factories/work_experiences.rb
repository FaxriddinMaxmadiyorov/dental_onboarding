FactoryBot.define do
  factory :work_experience do
    candidate_profile
    job_title { "Software Engineer" }
    company_name { "Test Company" }
  end
end
