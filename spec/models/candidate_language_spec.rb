require "rails_helper"

RSpec.describe CandidateLanguage, type: :model do
  let(:candidate_profile) { create(:candidate_profile) }
  let(:language) { create(:language) }

  describe "associations" do
    it "belongs to candidate_profile" do
      candidate_language = build(:candidate_language, candidate_profile: candidate_profile, language: language)
      expect(candidate_language.candidate_profile).to eq(candidate_profile)
    end

    it "belongs to language" do
      candidate_language = build(:candidate_language, candidate_profile: candidate_profile, language: language)
      expect(candidate_language.language).to eq(language)
    end

    it "is destroyed when candidate_profile is destroyed" do
      candidate_language = create(:candidate_language, candidate_profile: candidate_profile, language: language)
      expect { candidate_profile.destroy }.to change(CandidateLanguage, :count).by(-1)
    end
  end

  describe "validations" do
    it "is valid with a level present" do
      candidate_language = build(:candidate_language, candidate_profile: candidate_profile, language: language, level: "B2")
      expect(candidate_language).to be_valid
    end

    it "is invalid without a level" do
      candidate_language = build(:candidate_language, candidate_profile: candidate_profile, language: language, level: nil)
      expect(candidate_language).not_to be_valid
      expect(candidate_language.errors[:level]).to include("can't be blank")
    end

    it "is invalid without a candidate_profile" do
      candidate_language = build(:candidate_language, candidate_profile: nil, language: language)
      expect(candidate_language).not_to be_valid
    end

    it "is invalid without a language" do
      candidate_language = build(:candidate_language, candidate_profile: candidate_profile, language: nil)
      expect(candidate_language).not_to be_valid
    end
  end
end
