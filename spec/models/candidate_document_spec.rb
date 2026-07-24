require "rails_helper"

RSpec.describe CandidateDocument, type: :model do
  let(:candidate_profile) { create(:candidate_profile) }
  let(:pdf_file) do
    fixture_file_upload(
      Rails.root.join("spec/fixtures/files/sample.pdf"),
      "application/pdf"
    )
  end

  describe "validations" do
    it "is valid with an attached PDF file" do
      document = build(:candidate_document, candidate_profile: candidate_profile)
      expect(document).to be_valid
    end

    it "is invalid without a file" do
      document = build(:candidate_document, candidate_profile: candidate_profile)
      document.file.detach
      expect(document).not_to be_valid
      expect(document.errors[:file]).to include("can't be blank")
    end

    it "accepts application/pdf content type" do
      document = build(:candidate_document, candidate_profile: candidate_profile)
      document.file.attach(
        io: StringIO.new("fake content"),
        filename: "cv.pdf",
        content_type: "application/pdf"
      )
      expect(document).to be_valid
    end

    it "accepts application/msword content type" do
      document = build(:candidate_document, candidate_profile: candidate_profile)
      document.file.attach(
        io: StringIO.new("fake content"),
        filename: "cv.doc",
        content_type: "application/msword"
      )
      expect(document).to be_valid
    end

    it "accepts docx content type" do
      document = build(:candidate_document, candidate_profile: candidate_profile)
      document.file.attach(
        io: StringIO.new("fake content"),
        filename: "cv.docx",
        content_type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      )
      expect(document).to be_valid
    end

    it "rejects an unsupported file type" do
      document = build(:candidate_document, candidate_profile: candidate_profile)
      document.file.attach(
        io: StringIO.new("plain text"),
        filename: "cv.txt",
        content_type: "text/plain"
      )
      expect(document).not_to be_valid
      expect(document.errors[:file]).to include("must be a PDF, DOC, or DOCX file")
    end

    it "rejects a file larger than MAX_SIZE" do
      document = build(:candidate_document, candidate_profile: candidate_profile)
      document.file.attach(
        io: StringIO.new("fake content"),
        filename: "cv.pdf",
        content_type: "application/pdf"
      )
      allow(document.file).to receive(:byte_size).and_return((CandidateDocument::MAX_SIZE + 1).megabytes)

      expect(document).not_to be_valid
      expect(document.errors[:file]).to include("is too large (max #{CandidateDocument::MAX_SIZE} MB)")
    end

    it "accepts a file exactly at MAX_SIZE" do
      document = build(:candidate_document, candidate_profile: candidate_profile)
      document.file.attach(
        io: StringIO.new("fake content"),
        filename: "cv.pdf",
        content_type: "application/pdf"
      )
      allow(document.file).to receive(:byte_size).and_return(CandidateDocument::MAX_SIZE.megabytes)

      expect(document).to be_valid
    end
  end

  describe "enum parsing_status" do
    it "defaults to pending" do
      document = create(:candidate_document, candidate_profile: candidate_profile)
      expect(document.pending?).to be true
    end

    it "supports processing!" do
      document = create(:candidate_document, candidate_profile: candidate_profile)
      document.processing!
      expect(document.reload.parsing_status).to eq("processing")
    end

    it "supports completed!" do
      document = create(:candidate_document, candidate_profile: candidate_profile)
      document.completed!
      expect(document.reload.completed?).to be true
    end

    it "supports failed!" do
      document = create(:candidate_document, candidate_profile: candidate_profile)
      document.failed!
      expect(document.reload.failed?).to be true
    end

    it "provides scopes for each status" do
      pending_doc = create(:candidate_document, candidate_profile: candidate_profile)
      completed_doc = create(:candidate_document, candidate_profile: create(:candidate_profile), parsing_status: "completed")

      expect(CandidateDocument.pending).to include(pending_doc)
      expect(CandidateDocument.completed).to include(completed_doc)
      expect(CandidateDocument.pending).not_to include(completed_doc)
    end
  end

  describe "associations" do
    it "belongs to candidate_profile" do
      document = build(:candidate_document, candidate_profile: candidate_profile)
      expect(document.candidate_profile).to eq(candidate_profile)
    end

    it "is destroyed when candidate_profile is destroyed" do
      document = create(:candidate_document, candidate_profile: candidate_profile)
      expect { candidate_profile.destroy }.to change(CandidateDocument, :count).by(-1)
    end
  end
end
