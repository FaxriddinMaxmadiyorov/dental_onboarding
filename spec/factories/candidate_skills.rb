FactoryBot.define do
  factory :candidate_skill do
    candidate_profile
    skill

    trait :free_text do
      skill { nil }
      free_text_suggestion { "Some Skill" }
    end
  end
end
