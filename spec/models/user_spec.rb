require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it "has one candidate_profile" do
      user = create(:user)
      profile = create(:candidate_profile, user: user)
      expect(user.candidate_profile).to eq(profile)
    end

    it "destroys candidate_profile when user is destroyed" do
      user = create(:user)
      create(:candidate_profile, user: user)
      expect { user.destroy }.to change(CandidateProfile, :count).by(-1)
    end

    it "has many sessions" do
      user = create(:user)
      expect(user.sessions).to eq([])
    end

    it "destroys sessions when user is destroyed" do
      user = create(:user)
      user.sessions.create!
      expect { user.destroy }.to change(Session, :count).by(-1)
    end
  end

  describe "validations" do
    it "is valid with a unique, properly formatted email and password" do
      user = build(:user)
      expect(user).to be_valid
    end

    it "requires an email_address" do
      user = build(:user, email_address: nil)
      expect(user).not_to be_valid
      expect(user.errors[:email_address]).to include("can't be blank")
    end

    it "requires a unique email_address" do
      create(:user, email_address: "duplicate@example.com")
      user = build(:user, email_address: "duplicate@example.com")
      expect(user).not_to be_valid
      expect(user.errors[:email_address]).to include("has already been taken")
    end

    it "rejects an invalid email format" do
      user = build(:user, email_address: "not-an-email")
      expect(user).not_to be_valid
      expect(user.errors[:email_address]).to include("is invalid")
    end

    it "requires a password via has_secure_password" do
      user = User.new(email_address: "test@example.com")
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("can't be blank")
    end
  end

  describe "role enum" do
    it "defaults role appropriately when set explicitly" do
      user = create(:user, role: "candidate")
      expect(user.candidate?).to be true
    end

    it "supports admin role" do
      user = create(:user, :admin)
      expect(user.admin?).to be true
    end

    it "does not allow an invalid role" do
      expect { build(:user, role: "superuser") }.to raise_error(ArgumentError)
    end
  end
end
