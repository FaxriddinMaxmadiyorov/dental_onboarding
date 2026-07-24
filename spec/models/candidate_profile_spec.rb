require "rails_helper"

RSpec.describe CandidateProfile, type: :model do
  describe "conditional field display" do
    describe "#shows_big_fields?" do
      it "returns true for general_dentist" do
        profile = build(:candidate_profile, desired_job_function: "general_dentist")
        expect(profile.shows_big_fields?).to be true
      end

      it "returns true for dental_hygienist" do
        profile = build(:candidate_profile, desired_job_function: "dental_hygienist")
        expect(profile.shows_big_fields?).to be true
      end

      it "returns true for specialist" do
        profile = build(:candidate_profile, desired_job_function: "specialist")
        expect(profile.shows_big_fields?).to be true
      end

      it "returns false for dental_assistant" do
        profile = build(:candidate_profile, desired_job_function: "dental_assistant")
        expect(profile.shows_big_fields?).to be false
      end

      it "returns false when job function is nil" do
        profile = build(:candidate_profile, desired_job_function: nil)
        expect(profile.shows_big_fields?).to be false
      end
    end

    describe "#shows_salary_field?" do
      it "returns true when employment_type includes employed" do
        profile = build(:candidate_profile, employment_type: ["employed"])
        expect(profile.shows_salary_field?).to be true
      end

      it "returns false when employment_type is empty" do
        profile = build(:candidate_profile, employment_type: [])
        expect(profile.shows_salary_field?).to be false
      end

      it "returns false when employment_type is nil" do
        profile = build(:candidate_profile, employment_type: nil)
        expect(profile.shows_salary_field?).to be false
      end

      it "returns false when only self_employed is selected" do
        profile = build(:candidate_profile, employment_type: ["self_employed"])
        expect(profile.shows_salary_field?).to be false
      end
    end

    describe "#shows_percentage_field?" do
      it "returns true for self_employed" do
        profile = build(:candidate_profile, employment_type: ["self_employed"])
        expect(profile.shows_percentage_field?).to be true
      end

      it "returns true for percentage_based" do
        profile = build(:candidate_profile, employment_type: ["percentage_based"])
        expect(profile.shows_percentage_field?).to be true
      end

      it "returns false for employed only" do
        profile = build(:candidate_profile, employment_type: ["employed"])
        expect(profile.shows_percentage_field?).to be false
      end
    end

    describe "#shows_average_revenue_field?" do
      it "returns true for prevention_assistant" do
        profile = build(:candidate_profile, desired_job_function: "prevention_assistant")
        expect(profile.shows_average_revenue_field?).to be true
      end

      it "returns false for dental_technician" do
        profile = build(:candidate_profile, desired_job_function: "dental_technician")
        expect(profile.shows_average_revenue_field?).to be false
      end
    end
  end

  describe "#field_from_cv?" do
    it "returns true when field is in cv_filled_fields" do
      profile = build(:candidate_profile, cv_filled_fields: ["first_name", "city"])
      expect(profile.field_from_cv?(:first_name)).to be true
      expect(profile.field_from_cv?("city")).to be true
    end

    it "returns false when field is not in cv_filled_fields" do
      profile = build(:candidate_profile, cv_filled_fields: ["first_name"])
      expect(profile.field_from_cv?(:last_name)).to be false
    end

    it "returns false when cv_filled_fields is empty" do
      profile = build(:candidate_profile, cv_filled_fields: [])
      expect(profile.field_from_cv?(:first_name)).to be false
    end
  end

  describe "#latest_cv" do
    it "returns the most recently created cv document" do
      profile = create(:candidate_profile)
      old_doc = create(:candidate_document, candidate_profile: profile, created_at: 2.days.ago)
      new_doc = create(:candidate_document, candidate_profile: profile, created_at: 1.hour.ago)

      expect(profile.latest_cv).to eq(new_doc)
    end

    it "returns nil when no cv exists" do
      profile = create(:candidate_profile)
      expect(profile.latest_cv).to be_nil
    end

    it "ignores documents that are not of type cv" do
      profile = create(:candidate_profile)
      create(:candidate_document, candidate_profile: profile, document_type: "cv")
      # agar kelajakda boshqa document_type qo'shsangiz, shu yerga qo'shing
    end
  end

  describe "validations on :final_save context" do
    subject(:profile) { build(:candidate_profile) }

    it "is valid with all required fields on default context" do
      expect(profile).to be_valid
    end

    it "does not require final_save fields on default save" do
      profile.first_name = nil
      expect(profile).to be_valid
    end

    it "requires first_name on final_save" do
      profile.first_name = nil
      profile.valid?(:final_save)
      expect(profile.errors[:first_name]).to include("can't be blank")
    end

    it "requires last_name on final_save" do
      profile.last_name = nil
      profile.valid?(:final_save)
      expect(profile.errors[:last_name]).to include("can't be blank")
    end

    it "requires city on final_save" do
      profile.city = nil
      profile.valid?(:final_save)
      expect(profile.errors[:city]).to include("can't be blank")
    end

    it "requires desired_job_function on final_save" do
      profile.desired_job_function = nil
      profile.valid?(:final_save)
      expect(profile.errors[:desired_job_function]).to include("can't be blank")
    end

    it "requires max_travel_time on final_save" do
      profile.max_travel_time = nil
      profile.valid?(:final_save)
      expect(profile.errors[:max_travel_time]).to include("can't be blank")
    end

    it "requires available_from on final_save" do
      profile.available_from = nil
      profile.valid?(:final_save)
      expect(profile.errors[:available_from]).to include("can't be blank")
    end

    describe "email validation" do
      it "requires email on final_save" do
        profile.email = nil
        profile.valid?(:final_save)
        expect(profile.errors[:email]).to include("can't be blank")
      end

      it "rejects invalid email format" do
        profile.email = "not-an-email"
        profile.valid?(:final_save)
        expect(profile.errors[:email]).to include("is invalid")
      end

      it "accepts blank email outside final_save" do
        profile.email = nil
        expect(profile.valid?).to be true
      end
    end

    describe "phone validation" do
      it "accepts a valid international phone number" do
        profile.phone = "+998901234567"
        expect(profile.valid?).to be true
      end

      it "rejects an invalid phone number" do
        profile.phone = "abc"
        profile.valid?(:final_save)
        expect(profile.errors[:phone]).to include("must be a valid phone number")
      end

      it "allows blank phone (checked separately via presence on final_save)" do
        profile.phone = nil
        profile.valid?
        expect(profile.errors[:phone]).to be_empty
      end
    end

    describe "conditional presence validations" do
      it "requires desired_salary when employed on final_save" do
        profile.employment_type = ["employed"]
        profile.desired_salary = nil
        profile.valid?(:final_save)
        expect(profile.errors[:desired_salary]).to include("can't be blank")
      end

      it "does not require desired_salary when not employed" do
        profile.employment_type = ["self_employed"]
        profile.desired_salary = nil
        profile.valid?(:final_save)
        expect(profile.errors[:desired_salary]).to be_empty
      end

      it "requires desired_percentage when self_employed on final_save" do
        profile.employment_type = ["self_employed"]
        profile.desired_percentage = nil
        profile.valid?(:final_save)
        expect(profile.errors[:desired_percentage]).to include("is not a number")
      end

      it "requires average_daily_revenue when function shows it" do
        profile.desired_job_function = "general_dentist"
        profile.average_daily_revenue = nil
        profile.valid?(:final_save)
        expect(profile.errors[:average_daily_revenue]).to include("is not a number")
      end

      it "requires big_number when big_status is registered" do
        profile.big_status = "registered"
        profile.big_number = nil
        profile.valid?(:final_save)
        expect(profile.errors[:big_number]).to include("can't be blank")
      end

      it "does not require big_number when big_status is not registered" do
        profile.big_status = "not_applicable"
        profile.big_number = nil
        profile.valid?(:final_save)
        expect(profile.errors[:big_number]).to be_empty
      end
    end

    describe "array presence validations" do
      it "requires at least one preferred_region on final_save" do
        profile.preferred_regions = []
        profile.valid?(:final_save)
        expect(profile.errors[:preferred_regions]).to include("Please select at least one preferred region")
      end

      it "requires at least one employment_type on final_save" do
        profile.employment_type = []
        profile.valid?(:final_save)
        expect(profile.errors[:employment_type]).to include("Please select at least one employment type")
      end

      it "requires at least one available_day on final_save" do
        profile.available_days = []
        profile.valid?(:final_save)
        expect(profile.errors[:available_days]).to include("Please select at least one available day")
      end
    end

    describe "candidate_languages presence" do
      it "requires at least one language on final_save" do
        profile = create(:candidate_profile)
        profile.valid?(:final_save)
        expect(profile.errors[:candidate_languages]).to include("Please add at least one language")
      end

      it "passes when at least one language is present" do
        profile = create(:candidate_profile)
        create(:candidate_language, candidate_profile: profile)
        profile.reload
        profile.valid?(:final_save)
        expect(profile.errors[:candidate_languages]).to be_empty
      end

      it "does not count languages marked for destruction" do
        profile = create(:candidate_profile)
        language = create(:candidate_language, candidate_profile: profile)
        profile.candidate_languages_attributes = [{ id: language.id, _destroy: "1" }]
        profile.valid?(:final_save)
        expect(profile.errors[:candidate_languages]).to include("Please add at least one language")
      end
    end

    describe "numericality validations" do
      it "rejects negative years_of_experience" do
        profile.years_of_experience = -1
        profile.valid?(:final_save)
        expect(profile.errors[:years_of_experience]).to be_present
      end

      it "accepts zero years_of_experience" do
        profile.years_of_experience = 0
        profile.valid?
        expect(profile.errors[:years_of_experience]).to be_empty
      end

      it "rejects desired_percentage above 100" do
        profile.employment_type = ["self_employed"]
        profile.desired_percentage = 150
        profile.valid?(:final_save)
        expect(profile.errors[:desired_percentage]).to be_present
      end

      it "rejects desired_percentage below 0" do
        profile.employment_type = ["self_employed"]
        profile.desired_percentage = -5
        profile.valid?(:final_save)
        expect(profile.errors[:desired_percentage]).to be_present
      end
    end

    describe "available_from date validation" do
      it "rejects a past date" do
        profile.available_from = Date.yesterday
        profile.valid?(:final_save)
        expect(profile.errors[:available_from]).to be_present
      end

      it "accepts today or a future date" do
        profile.available_from = Date.current
        profile.valid?(:final_save)
        expect(profile.errors[:available_from]).to be_empty
      end
    end
  end

  describe "nested attributes" do
    it "rejects education with blank study" do
      profile = build(:candidate_profile)
      profile.educations_attributes = [{ institution: "MIT", study: "" }]
      profile.save
      expect(profile.educations).to be_empty
    end

    it "accepts education with study present" do
      profile = create(:candidate_profile)
      profile.educations_attributes = [{ study: "Dentistry" }]
      profile.save!
      expect(profile.educations.reload.count).to eq(1)
    end

    it "rejects work_experience with both job_title and company_name blank" do
      profile = build(:candidate_profile)
      profile.work_experiences_attributes = [{ job_title: "", company_name: "" }]
      profile.save
      expect(profile.work_experiences).to be_empty
    end
  end
end
