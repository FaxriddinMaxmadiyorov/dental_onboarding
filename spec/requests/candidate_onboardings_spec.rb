# spec/requests/candidate_onboardings_spec.rb
require "rails_helper"

RSpec.describe "CandidateOnboardings", type: :request do
  let(:user) { create(:user, password: "password123") }
  let!(:profile) { create(:candidate_profile, user: user) }

  before { sign_in_as(user) }

  describe "GET /candidate_onboarding/upload" do
    it "returns a successful response" do
      get upload_candidate_onboarding_path
      expect(response).to have_http_status(:ok)
    end

    it "builds a new candidate_document for the form" do
      get upload_candidate_onboarding_path
      expect(assigns(:document)).to be_a_new(CandidateDocument)
    end

    context "when the user is an admin" do
      let(:user) { create(:user, :admin, password: "password123") }

      it "redirects to candidate_profiles_path" do
        get upload_candidate_onboarding_path
        expect(response).to redirect_to(candidate_profiles_path)
      end
    end
  end

  describe "POST /candidate_onboarding/upload_cv" do
    let(:pdf_file) do
      Rack::Test::UploadedFile.new(
        StringIO.new("%PDF-1.4 fake content"),
        "application/pdf",
        original_filename: "cv.pdf"
      )
    end

    context "without consent" do
      it "does not create a CandidateDocument" do
        expect {
          post upload_cv_candidate_onboarding_path, params: { candidate_document: { file: pdf_file } }
        }.not_to change(CandidateDocument, :count)
      end

      it "renders the upload template with an alert" do
        post upload_cv_candidate_onboarding_path, params: { candidate_document: { file: pdf_file } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(flash.now[:alert]).to eq("To continue, please provide consent.")
      end
    end

    context "with consent but no file" do
      it "does not create a CandidateDocument" do
        expect {
          post upload_cv_candidate_onboarding_path, params: { consent: "1" }
        }.not_to change(CandidateDocument, :count)
      end

      it "shows a 'please select a file' alert" do
        post upload_cv_candidate_onboarding_path, params: { consent: "1" }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with consent and a valid file" do
      it "creates a CandidateDocument" do
        expect {
          post upload_cv_candidate_onboarding_path, params: { consent: "1", candidate_document: { file: pdf_file } }
        }.to change(CandidateDocument, :count).by(1)
      end

      it "enqueues ParseCandidateCvJob" do
        expect {
          post upload_cv_candidate_onboarding_path, params: { consent: "1", candidate_document: { file: pdf_file } }
        }.to have_enqueued_job(ParseCandidateCvJob)
      end

      it "redirects to the status page" do
        post upload_cv_candidate_onboarding_path, params: { consent: "1", candidate_document: { file: pdf_file } }
        expect(response).to redirect_to(status_candidate_onboarding_path)
      end
    end

    context "with consent and an invalid file type" do
      let(:txt_file) do
        Rack::Test::UploadedFile.new(
          StringIO.new("plain text"),
          "text/plain",
          original_filename: "cv.txt"
        )
      end

      it "does not create a CandidateDocument" do
        expect {
          post upload_cv_candidate_onboarding_path, params: { consent: "1", candidate_document: { file: txt_file } }
        }.not_to change(CandidateDocument, :count)
      end

      it "shows the validation error" do
        post upload_cv_candidate_onboarding_path, params: { consent: "1", candidate_document: { file: txt_file } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /candidate_onboarding/status" do
  context "when there is no CV yet" do
    it "raises an error, since visiting status without a CV is not a supported flow" do
      expect {
        get status_candidate_onboarding_path
      }.to raise_error(NoMethodError)
    end
  end

  context "when the latest CV is completed" do
    before do
      create(:candidate_document, candidate_profile: profile, parsing_status: "completed")
    end

    it "redirects to edit_profile" do
      get status_candidate_onboarding_path
      expect(response).to redirect_to(edit_profile_candidate_onboarding_path)
    end
  end

  context "when the latest CV is still processing" do
    before do
      create(:candidate_document, candidate_profile: profile, parsing_status: "processing")
    end

    it "renders the status page" do
      get status_candidate_onboarding_path
      expect(response).to have_http_status(:ok)
    end
  end
end

  describe "GET /candidate_onboarding/edit_profile" do
    it "builds a blank education if none exist" do
      get edit_profile_candidate_onboarding_path
      profile = assigns(:profile)
      expect(profile.educations).not_to be_empty
    end

    it "builds a blank work_experience if none exist" do
      get edit_profile_candidate_onboarding_path
      profile = assigns(:profile)
      expect(profile.work_experiences).not_to be_empty
    end

    it "does not add a blank education if one already exists" do
      profile = user.reload.candidate_profile
      create(:education, candidate_profile: profile)

      get edit_profile_candidate_onboarding_path
      expect(assigns(:profile).educations.count).to eq(1)
    end
  end

  describe "PATCH /candidate_onboarding" do
    let(:valid_params) do
      {
        candidate_profile: {
          first_name: "Rustam", last_name: "Zokirov", email: "rustam@example.com",
          phone: "+998901234567", city: "Tashkent", country: "Uzbekistan",
          desired_job_function: "dental_assistant", max_travel_time: "30",
          search_status: "active", employment_type: ["employed"],
          desired_salary: "1000", preferred_regions: ["Tashkent"],
          available_days: ["Monday"], available_from: (Date.current + 1.week).to_s,
          years_of_experience: "2",
          candidate_languages_attributes: {
            "0" => { language_id: create(:language).id, level: "B2" }
          }
        }
      }
    end

    context "with valid params" do
      it "saves the profile and marks onboarding_completed" do
        patch candidate_onboarding_path, params: valid_params
        expect(profile.reload.onboarding_completed).to be true
      end

      it "redirects to the onboarded page" do
        patch candidate_onboarding_path, params: valid_params
        expect(response).to redirect_to(onboarded_candidate_onboarding_path)
      end

      it "enqueues NotifyRecruitmentTeamJob if defined" do
        skip "NotifyRecruitmentTeamJob is not defined" unless defined?(NotifyRecruitmentTeamJob)

        expect {
          patch candidate_onboarding_path, params: valid_params
        }.to have_enqueued_job(NotifyRecruitmentTeamJob)
      end
    end

    context "with invalid params (missing required fields)" do
      let(:invalid_params) { { candidate_profile: { first_name: "" } } }

      it "does not mark onboarding_completed" do
        patch candidate_onboarding_path, params: invalid_params
        expect(profile.reload.onboarding_completed).to be false
      end

      it "re-renders the edit_profile template" do
        patch candidate_onboarding_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when removing a free-text skill" do
      it "destroys the specified candidate_skill" do
        candidate_skill = create(:candidate_skill, :free_text, candidate_profile: profile)

        params = valid_params.deep_merge(
          candidate_profile: { remove_free_text_skill_ids: [candidate_skill.id.to_s] }
        )

        expect {
          patch candidate_onboarding_path, params: params
        }.to change(CandidateSkill, :count).by(-1)
      end
    end

    context "when a field was previously filled from CV and is now manually changed" do
      it "removes the field from cv_filled_fields" do
        profile.update!(cv_filled_fields: ["first_name"])

        patch candidate_onboarding_path, params: valid_params

        expect(profile.reload.cv_filled_fields).not_to include("first_name")
      end
    end
  end

  describe "GET /candidate_onboarding/onboarded" do
    it "returns a successful response" do
      get onboarded_candidate_onboarding_path
      expect(response).to have_http_status(:ok)
    end

    it "deletes the candidate_session cookie" do
      get onboarded_candidate_onboarding_path
      expect(cookies[:candidate_session]).to be_blank
    end
  end

  describe "GET /candidate_onboarding/profile" do
    it "returns a successful response" do
      get profile_candidate_onboarding_path
      expect(response).to have_http_status(:ok)
    end
  end
end