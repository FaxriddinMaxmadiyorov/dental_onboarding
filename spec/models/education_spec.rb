require "rails_helper"

RSpec.describe Education, type: :model do
  let(:candidate_profile) { create(:candidate_profile) }

  describe "associations" do
    it "belongs to candidate_profile" do
      education = build(:education, candidate_profile: candidate_profile)
      expect(education.candidate_profile).to eq(candidate_profile)
    end
  end

  describe "validations" do
    it "is valid with a study field present" do
      education = build(:education, candidate_profile: candidate_profile, study: "Dentistry")
      expect(education).to be_valid
    end

    it "is invalid without a study field" do
      education = build(:education, candidate_profile: candidate_profile, study: nil)
      expect(education).not_to be_valid
      expect(education.errors[:study]).to include("can't be blank")
    end

    it "does not require institution" do
      education = build(:education, candidate_profile: candidate_profile, institution: nil, study: "Dentistry")
      expect(education).to be_valid
    end
  end

  describe "LEVELS constant" do
    it "includes the expected education levels" do
      expect(Education::LEVELS).to match_array(%w[MBO HBO Bachelor Master Doctor Course])
    end
  end
end
