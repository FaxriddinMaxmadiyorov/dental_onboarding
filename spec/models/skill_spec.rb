require "rails_helper"

RSpec.describe Skill, type: :model do
  describe "associations" do
    it "has many candidate_skills" do
      skill = create(:skill)
      candidate_skill = create(:candidate_skill, skill: skill)
      expect(skill.candidate_skills).to include(candidate_skill)
    end
  end

  describe ".for_function" do
    it "returns only skills matching the given function_group" do
      dentist_skill = create(:skill, function_group: "dentist", name: "Endodontics")
      hygienist_skill = create(:skill, function_group: "dental_hygienist", name: "Scaling")

      result = Skill.for_function("dentist")

      expect(result).to include(dentist_skill)
      expect(result).not_to include(hygienist_skill)
    end

    it "returns an empty relation for a function_group with no skills" do
      expect(Skill.for_function("nonexistent_group")).to be_empty
    end
  end
end
