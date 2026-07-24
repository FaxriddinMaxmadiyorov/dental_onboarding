FactoryBot.define do
  factory :skill do
    sequence(:name) { |n| "Skill #{n}" }
    function_group { "dentist" }
  end
end
