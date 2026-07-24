FactoryBot.define do
  factory :education do
    candidate_profile
    study { "Computer Science" }
    institution { "Tashkent University" }
    level { "Bachelor" }
  end
end
