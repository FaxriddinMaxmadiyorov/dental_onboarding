require "rails_helper"

RSpec.describe CandidateOnboardingsHelper, type: :helper do
  describe "#field_status_label" do
    context "when the field was extracted from CV" do
      it "shows the 'Extracted from CV' label" do
        profile = build(:candidate_profile, cv_filled_fields: ["first_name"], first_name: "Rustam")

        result = helper.field_status_label(profile, :first_name)

        expect(result).to have_css("span.text-amber-600", text: "Extracted from CV; please check")
      end

      it "shows the CV label even when the field is required and present" do
        profile = build(:candidate_profile, cv_filled_fields: ["city"], city: "Tashkent")

        result = helper.field_status_label(profile, :city, required: true)

        expect(result).to have_css("span.text-amber-600")
        expect(result).not_to have_css("span.text-red-500")
      end
    end

    context "when the field is required and blank, and not from CV" do
      it "shows the 'Missing' label" do
        profile = build(:candidate_profile, cv_filled_fields: [], first_name: nil)

        result = helper.field_status_label(profile, :first_name, required: true)

        expect(result).to have_css("span.text-red-500", text: "Missing")
      end
    end

    context "when the field is required but present, and not from CV" do
      it "returns nil (no label shown)" do
        profile = build(:candidate_profile, cv_filled_fields: [], first_name: "Rustam")

        result = helper.field_status_label(profile, :first_name, required: true)

        expect(result).to be_nil
      end
    end

    context "when the field is not required and blank" do
      it "returns nil (no 'Missing' label shown)" do
        profile = build(:candidate_profile, cv_filled_fields: [], motivation: nil)

        result = helper.field_status_label(profile, :motivation, required: false)

        expect(result).to be_nil
      end
    end

    context "when the field is not required and not from CV, default required value" do
      it "returns nil by default when required is not passed" do
        profile = build(:candidate_profile, cv_filled_fields: [], professional_summary: nil)

        result = helper.field_status_label(profile, :professional_summary)

        expect(result).to be_nil
      end
    end
  end
end
