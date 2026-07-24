require "rails_helper"

RSpec.describe CandidateSkill, type: :model do
  let(:candidate_profile) { create(:candidate_profile) }

  describe "associations" do
    it "belongs to candidate_profile" do
      candidate_skill = build(:candidate_skill, candidate_profile: candidate_profile)
      expect(candidate_skill.candidate_profile).to eq(candidate_profile)
    end

    it "can belong to a skill" do
      skill = create(:skill)
      candidate_skill = build(:candidate_skill, candidate_profile: candidate_profile, skill: skill)
      expect(candidate_skill.skill).to eq(skill)
    end

    it "allows skill to be nil (optional) for free-text suggestions" do
      candidate_skill = build(:candidate_skill, :free_text, candidate_profile: candidate_profile)
      expect(candidate_skill).to be_valid
      expect(candidate_skill.skill).to be_nil
    end
  end

  describe "free_text_suggestion" do
    it "stores a free-text skill name when no matching Skill exists" do
      candidate_skill = create(:candidate_skill, :free_text, candidate_profile: candidate_profile,
                                free_text_suggestion: "WebSockets")
      expect(candidate_skill.free_text_suggestion).to eq("WebSockets")
      expect(candidate_skill.skill_id).to be_nil
    end
  end
end
