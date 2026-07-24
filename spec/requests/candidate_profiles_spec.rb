# spec/requests/candidate_profiles_spec.rb
require "rails_helper"

RSpec.describe "CandidateProfiles", type: :request do
  let(:admin_user) { create(:user, :admin, password: "password123") }
  let(:candidate_user) { create(:user, role: "candidate", password: "password123") }
  let!(:profile) { create(:candidate_profile, onboarding_completed: true) }

  describe "GET /candidate_profiles" do
    context "when signed in as admin" do
      before { sign_in_as(admin_user) }

      it "returns a successful response" do
        get candidate_profiles_path
        expect(response).to have_http_status(:ok)
      end

      it "assigns only onboarding_completed profiles" do
        incomplete_profile = create(:candidate_profile, onboarding_completed: false)

        get candidate_profiles_path

        expect(assigns(:profiles)).to include(profile)
        expect(assigns(:profiles)).not_to include(incomplete_profile)
      end
    end

    context "when signed in as a candidate" do
      before { sign_in_as(candidate_user) }

      it "redirects to root_path with an authorization alert" do
        get candidate_profiles_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      end
    end

    context "when not signed in" do
      it "redirects to login" do
        get candidate_profiles_path
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "GET /candidate_profiles/:id" do
    context "when signed in as admin" do
      before { sign_in_as(admin_user) }

      it "returns a successful response" do
        get candidate_profile_path(profile)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when signed in as a candidate" do
      before { sign_in_as(candidate_user) }

      it "redirects to root_path" do
        get candidate_profile_path(profile)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /candidate_profiles/:id/edit" do
    context "when signed in as admin" do
      before { sign_in_as(admin_user) }

      it "returns a successful response" do
        get edit_candidate_profile_path(profile)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when signed in as a candidate" do
      before { sign_in_as(candidate_user) }

      it "redirects to root_path" do
        get edit_candidate_profile_path(profile)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /candidate_profiles/:id" do
    before { create(:candidate_language, candidate_profile: profile) }

    let(:valid_params) { { candidate_profile: { first_name: "UpdatedName" } } }

    context "when signed in as admin" do
      before { sign_in_as(admin_user) }

      it "debug: shows validation errors", focus: true do
            patch candidate_profile_path(profile), params: valid_params
            profile.reload
            profile.valid?(:final_save)
            end

      it "redirects to candidate_profiles_path" do
        patch candidate_profile_path(profile), params: valid_params

        expect(response).to redirect_to(candidate_profiles_path)
      end

      it "removes specified free-text skills" do
        candidate_skill = create(:candidate_skill, :free_text, candidate_profile: profile)

        params = valid_params.deep_merge(
          candidate_profile: { remove_free_text_skill_ids: [candidate_skill.id.to_s] }
        )

        expect {
          patch candidate_profile_path(profile), params: params
        }.to change(CandidateSkill, :count).by(-1)
      end

      context "with invalid params" do
        let(:invalid_params) { { candidate_profile: { first_name: "" } } }

        it "does not update the profile" do
          patch candidate_profile_path(profile), params: invalid_params
          expect(profile.reload.first_name).not_to eq("")
        end

        it "renders the edit template with unprocessable_content status" do
          patch candidate_profile_path(profile), params: invalid_params
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end

    context "when signed in as a candidate" do
      before { sign_in_as(candidate_user) }

      it "redirects to root_path without updating the profile" do
        patch candidate_profile_path(profile), params: valid_params
        expect(response).to redirect_to(root_path)
        expect(profile.reload.first_name).not_to eq("UpdatedName")
      end
    end
  end

  describe "DELETE /candidate_profiles/:id" do
    context "when signed in as admin" do
      before { sign_in_as(admin_user) }

      it "destroys the profile" do
        profile_to_delete = create(:candidate_profile, onboarding_completed: true)

        expect {
          delete candidate_profile_path(profile_to_delete)
        }.to change(CandidateProfile, :count).by(-1)
      end

      it "redirects to candidate_profiles_path" do
        delete candidate_profile_path(profile)
        expect(response).to redirect_to(candidate_profiles_path)
      end
    end

    context "when signed in as a candidate" do
      before { sign_in_as(candidate_user) }

      it "redirects to root_path without destroying the profile" do
        expect {
          delete candidate_profile_path(profile)
        }.not_to change(CandidateProfile, :count)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end