FactoryBot.define do
  factory :candidate_profile do
    user
    first_name { "Test" }
    last_name { "Candidate" }
    email { "candidate@example.com" }
    phone { "+998901234567" }
    city { "Tashkent" }
    country { "Uzbekistan" }
    desired_job_function { "dental_assistant" }
    max_travel_time { 30 }
    search_status { "active" }
    employment_type { ["employed"] }
    desired_salary { 1000 }
    preferred_regions { ["Tashkent"] }
    available_days { ["Monday"] }
    available_from { Date.current + 1.week }
    years_of_experience { 2 }
  end
end
