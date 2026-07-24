require "rails_helper"

RSpec.describe CandidateProfilePolicy do
  let(:admin_user) { create(:user, :admin) }
  let(:candidate_user) { create(:user, role: "candidate") }
  let(:candidate_profile) { create(:candidate_profile) }

  describe "for an admin user" do
    subject(:policy) { described_class.new(admin_user, candidate_profile) }

    it "permits index" do
      expect(policy.index?).to be true
    end

    it "permits show" do
      expect(policy.show?).to be true
    end

    it "permits edit" do
      expect(policy.edit?).to be true
    end

    it "permits update" do
      expect(policy.update?).to be true
    end

    it "permits destroy" do
      expect(policy.destroy?).to be true
    end
  end

  describe "for a candidate user" do
    subject(:policy) { described_class.new(candidate_user, candidate_profile) }

    it "forbids index" do
      expect(policy.index?).to be false
    end

    it "forbids show" do
      expect(policy.show?).to be false
    end

    it "forbids edit" do
      expect(policy.edit?).to be false
    end

    it "forbids update" do
      expect(policy.update?).to be false
    end

    it "forbids destroy" do
      expect(policy.destroy?).to be false
    end
  end

  describe "Scope" do
    let!(:profile_one) { create(:candidate_profile) }
    let!(:profile_two) { create(:candidate_profile) }

    context "when the user is an admin" do
      it "returns all candidate profiles" do
        scope = CandidateProfilePolicy::Scope.new(admin_user, CandidateProfile).resolve
        expect(scope).to include(profile_one, profile_two)
      end
    end

    context "when the user is a candidate" do
      it "returns no candidate profiles" do
        scope = CandidateProfilePolicy::Scope.new(candidate_user, CandidateProfile).resolve
        expect(scope).to be_empty
      end
    end
  end
end
