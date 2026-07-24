require "rails_helper"

RSpec.describe WorkExperience, type: :model do
  let(:candidate_profile) { create(:candidate_profile) }

  describe "associations" do
    it "belongs to candidate_profile" do
      we = build(:work_experience, candidate_profile: candidate_profile)
      expect(we.candidate_profile).to eq(candidate_profile)
    end
  end

  describe "validations" do
    it "is valid with job_title and company_name present" do
      we = build(:work_experience, candidate_profile: candidate_profile,
                  job_title: "Engineer", company_name: "Acme")
      expect(we).to be_valid
    end

    it "is invalid without job_title" do
      we = build(:work_experience, candidate_profile: candidate_profile, job_title: nil)
      expect(we).not_to be_valid
      expect(we.errors[:job_title]).to include("can't be blank")
    end

    it "is invalid without company_name" do
      we = build(:work_experience, candidate_profile: candidate_profile, company_name: nil)
      expect(we).not_to be_valid
      expect(we.errors[:company_name]).to include("can't be blank")
    end
  end
end
