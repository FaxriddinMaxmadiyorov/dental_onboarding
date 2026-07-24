require "rails_helper"

RSpec.describe ProfilePrefillService, type: :service do
  let(:profile) do
    create(:candidate_profile,
           first_name: nil, last_name: nil, email: nil, phone: nil, city: nil, country: nil,
           desired_job_function: nil, years_of_experience: nil, big_number: nil, professional_summary: nil)
  end

  describe "#call" do
    context "with a fresh profile and full parsed data" do
      let(:parsed_data) do
        {
          "first_name" => "Rustam",
          "last_name" => "Zokirov",
          "phone" => "998901234567",
          "city" => "Tashkent",
          "country" => "Uzbekistan",
          "desired_job_function_guess" => "general_dentist",
          "big_number" => "12345",
          "years_of_combined_experience" => 4,
          "professional_summary" => "Experienced software engineer.",
          "educations" => [
            { "institution" => "Test University", "study" => "Computer Science",
              "city_country" => "Tashkent", "level" => "Bachelor", "start_date" => nil, "end_date" => nil }
          ],
          "work_experiences" => [
            { "job_title" => "Engineer", "company_name" => "Acme",
              "responsibilities" => "Built stuff", "start_date" => "2020-01", "end_date" => nil, "current_job" => true }
          ],
          "skills" => ["Ruby", "Python"],
          "languages" => [{ "name" => "English", "level" => "B2" }]
        }
      end

      it "fills all blank personal fields" do
        described_class.new(profile, parsed_data).call
        profile.reload

        expect(profile.first_name).to eq("Rustam")
        expect(profile.last_name).to eq("Zokirov")
        expect(profile.phone).to eq("998901234567")
        expect(profile.city).to eq("Tashkent")
        expect(profile.country).to eq("Uzbekistan")
      end

      it "fills job preference fields" do
        described_class.new(profile, parsed_data).call
        expect(profile.reload.desired_job_function).to eq("general_dentist")
      end

      it "fills employment fields" do
        described_class.new(profile, parsed_data).call
        profile.reload

        expect(profile.big_number).to eq("12345")
        expect(profile.years_of_experience).to eq(4)
        expect(profile.professional_summary).to eq("Experienced software engineer.")
      end

      it "creates education records marked as from_cv" do
        described_class.new(profile, parsed_data).call
        education = profile.educations.reload.first

        expect(education.study).to eq("Computer Science")
        expect(education.from_cv).to be true
      end

      it "creates work_experience records marked as from_cv" do
        described_class.new(profile, parsed_data).call
        we = profile.work_experiences.reload.first

        expect(we.job_title).to eq("Engineer")
        expect(we.from_cv).to be true
      end

      it "matches known skills to existing Skill records" do
        create(:skill, name: "Ruby")
        described_class.new(profile, parsed_data).call

        candidate_skill = profile.candidate_skills.reload.find_by(free_text_suggestion: nil)
        expect(candidate_skill.skill.name).to eq("Ruby")
      end

      it "stores unmatched skills as free_text_suggestion" do
        described_class.new(profile, parsed_data).call

        suggestion = profile.candidate_skills.reload.find_by(skill_id: nil, free_text_suggestion: "Python")
        expect(suggestion).to be_present
      end

      it "creates candidate_languages, creating the Language if needed" do
        described_class.new(profile, parsed_data).call
        profile.reload

        expect(profile.candidate_languages.count).to eq(1)
        expect(profile.candidate_languages.first.language.name).to eq("English")
        expect(profile.candidate_languages.first.level).to eq("B2")
      end

      it "records filled fields in cv_filled_fields" do
        described_class.new(profile, parsed_data).call
        profile.reload

        expect(profile.cv_filled_fields).to include(
          "first_name", "last_name", "phone", "city", "country",
          "desired_job_function", "big_number", "years_of_experience", "professional_summary"
        )
      end
    end

    context "when a field is already manually filled by the candidate (not from CV)" do
      let(:profile) { create(:candidate_profile, first_name: "Manual Name", cv_filled_fields: []) }
      let(:parsed_data) { { "first_name" => "CV Name" } }

      it "does not overwrite the manually entered value" do
        described_class.new(profile, parsed_data).call
        expect(profile.reload.first_name).to eq("Manual Name")
      end

      it "does not add the field to cv_filled_fields" do
        described_class.new(profile, parsed_data).call
        expect(profile.reload.cv_filled_fields).not_to include("first_name")
      end
    end

    context "when a field was previously filled by a CV upload, and a new CV is uploaded" do
      let(:profile) { create(:candidate_profile, first_name: "Old CV Name", cv_filled_fields: ["first_name"]) }
      let(:parsed_data) { { "first_name" => "New CV Name" } }

      it "overwrites the value with the new CV's data" do
        described_class.new(profile, parsed_data).call
        expect(profile.reload.first_name).to eq("New CV Name")
      end

      it "keeps the field in cv_filled_fields" do
        described_class.new(profile, parsed_data).call
        expect(profile.reload.cv_filled_fields).to include("first_name")
      end
    end

    context "when a field is blank in the new parsed data" do
      let(:profile) { create(:candidate_profile, first_name: "Existing Name") }
      let(:parsed_data) { { "first_name" => nil } }

      it "does not change the existing value" do
        described_class.new(profile, parsed_data).call
        expect(profile.reload.first_name).to eq("Existing Name")
      end
    end

    context "when re-uploading a CV (idempotency check on educations/work_experiences)" do
      let(:profile) { create(:candidate_profile) }

      it "removes old from_cv: true educations before adding new ones" do
        old_education = create(:education, candidate_profile: profile, study: "Old Study", from_cv: true)

        parsed_data = {
          "educations" => [{ "institution" => nil, "study" => "New Study", "city_country" => nil,
                              "level" => nil, "start_date" => nil, "end_date" => nil }]
        }

        described_class.new(profile, parsed_data).call
        profile.reload

        expect(profile.educations).not_to include(old_education)
        expect(profile.educations.pluck(:study)).to contain_exactly("New Study")
      end

      it "does not remove educations that were manually added by the candidate (from_cv: false)" do
        manual_education = create(:education, candidate_profile: profile, study: "Manual Study", from_cv: false)

        parsed_data = {
          "educations" => [{ "institution" => nil, "study" => "New CV Study", "city_country" => nil,
                              "level" => nil, "start_date" => nil, "end_date" => nil }]
        }

        described_class.new(profile, parsed_data).call
        profile.reload

        expect(profile.educations).to include(manual_education)
        expect(profile.educations.pluck(:study)).to include("Manual Study", "New CV Study")
      end

      it "removes old from_cv: true work_experiences before adding new ones" do
        old_we = create(:work_experience, candidate_profile: profile, job_title: "Old Job", from_cv: true)

        parsed_data = {
          "work_experiences" => [{ "job_title" => "New Job", "company_name" => "New Co",
                                    "responsibilities" => nil, "start_date" => nil, "end_date" => nil, "current_job" => false }]
        }

        described_class.new(profile, parsed_data).call
        profile.reload

        expect(profile.work_experiences).not_to include(old_we)
        expect(profile.work_experiences.pluck(:job_title)).to contain_exactly("New Job")
      end
    end

    context "with empty or missing arrays in parsed data" do
      let(:profile) { create(:candidate_profile) }
      let(:parsed_data) { {} }

      it "does not raise an error" do
        expect { described_class.new(profile, parsed_data).call }.not_to raise_error
      end

      it "does not create any educations" do
        described_class.new(profile, parsed_data).call
        expect(profile.educations.reload).to be_empty
      end

      it "does not create any work_experiences" do
        described_class.new(profile, parsed_data).call
        expect(profile.work_experiences.reload).to be_empty
      end

      it "does not create any skills" do
        described_class.new(profile, parsed_data).call
        expect(profile.candidate_skills.reload).to be_empty
      end
    end

    context "when educations have blank study" do
      let(:profile) { create(:candidate_profile) }
      let(:parsed_data) do
        { "educations" => [{ "institution" => "Some Uni", "study" => "", "city_country" => nil,
                              "level" => nil, "start_date" => nil, "end_date" => nil }] }
      end

      it "skips the education entry" do
        described_class.new(profile, parsed_data).call
        expect(profile.educations.reload).to be_empty
      end
    end

    context "when work_experiences have both job_title and company_name blank" do
      let(:profile) { create(:candidate_profile) }
      let(:parsed_data) do
        { "work_experiences" => [{ "job_title" => "", "company_name" => "",
                                    "responsibilities" => nil, "start_date" => nil, "end_date" => nil, "current_job" => false }] }
      end

      it "skips the work_experience entry" do
        described_class.new(profile, parsed_data).call
        expect(profile.work_experiences.reload).to be_empty
      end
    end

    context "when the same skill already exists on the profile" do
      let(:profile) { create(:candidate_profile) }
      let(:skill) { create(:skill, name: "Ruby") }
      let(:parsed_data) { { "skills" => ["Ruby"] } }

      it "does not create a duplicate CandidateSkill" do
        create(:candidate_skill, candidate_profile: profile, skill: skill)

        expect {
          described_class.new(profile, parsed_data).call
        }.not_to change(CandidateSkill, :count)
      end
    end

    context "when the same language already exists on the profile" do
      let(:profile) { create(:candidate_profile) }
      let(:language) { create(:language, name: "English") }
      let(:parsed_data) { { "languages" => [{ "name" => "English", "level" => "B2" }] } }

      it "does not create a duplicate CandidateLanguage" do
        create(:candidate_language, candidate_profile: profile, language: language, level: "B2")

        expect {
          described_class.new(profile, parsed_data).call
        }.not_to change(CandidateLanguage, :count)
      end
    end

    context "when an invalid nested attribute would cause a save failure" do
      let(:profile) { create(:candidate_profile) }

      it "rolls back the entire transaction" do
        allow_any_instance_of(CandidateProfile).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(profile))

        parsed_data = {
          "educations" => [{ "institution" => nil, "study" => "Should Rollback", "city_country" => nil,
                              "level" => nil, "start_date" => nil, "end_date" => nil }]
        }

        expect {
          begin
            described_class.new(profile, parsed_data).call
          rescue ActiveRecord::RecordInvalid
            # expected
          end
        }.not_to change { profile.educations.reload.count }
      end
    end
  end
end
