FactoryBot.define do
  factory :candidate_language do
    candidate_profile
    language
    level { "B2" }
  end
end
