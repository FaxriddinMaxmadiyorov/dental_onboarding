require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let(:user) { create(:user, password: "password123") }

  describe "GET /login" do
    it "returns a successful response" do
      get login_path
      expect(response).to have_http_status(:ok)
    end

    it "does not require authentication" do
      get login_path
      expect(response).not_to redirect_to(login_path)
    end
  end

  describe "POST /login" do
    context "with valid credentials" do
      it "signs in the user" do
        post login_path, params: { email_address: user.email_address, password: "password123" }
        expect(response).to redirect_to(root_path)
      end

      it "sets a success notice" do
        post login_path, params: { email_address: user.email_address, password: "password123" }
        expect(flash[:notice]).to eq("Signed in successfully.")
      end

      it "creates a new session for the user" do
        expect {
          post login_path, params: { email_address: user.email_address, password: "password123" }
        }.to change(Session, :count).by(1)
      end

      it "sets the candidate as authenticated for subsequent requests" do
        post login_path, params: { email_address: user.email_address, password: "password123" }
        get upload_candidate_onboarding_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "with an invalid password" do
      it "does not sign in the user" do
        post login_path, params: { email_address: user.email_address, password: "wrongpassword" }
        expect(response).to redirect_to(login_path)
      end

      it "sets an alert message" do
        post login_path, params: { email_address: user.email_address, password: "wrongpassword" }
        expect(flash[:alert]).to eq("Try another email address or password.")
      end

      it "does not create a session" do
        expect {
          post login_path, params: { email_address: user.email_address, password: "wrongpassword" }
        }.not_to change(Session, :count)
      end
    end

    context "with a non-existent email" do
      it "does not sign in the user" do
        post login_path, params: { email_address: "nobody@example.com", password: "password123" }
        expect(response).to redirect_to(login_path)
        expect(flash[:alert]).to eq("Try another email address or password.")
      end
    end
  end

  describe "DELETE /logout" do
    before do
      post login_path, params: { email_address: user.email_address, password: "password123" }
    end

    it "signs out the user" do
      delete logout_path
      expect(response).to redirect_to(login_path)
    end

    it "sets a success notice" do
      delete logout_path
      expect(flash[:notice]).to eq("Signed out successfully.")
    end

    it "destroys the session" do
      expect {
        delete logout_path
      }.to change(Session, :count).by(-1)
    end

    it "requires re-authentication for subsequent requests" do
      delete logout_path
      get upload_candidate_onboarding_path
      expect(response).to redirect_to(login_path)
    end
  end
end
