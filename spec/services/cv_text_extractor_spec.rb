# spec/services/cv_text_extractor_spec.rb
require "rails_helper"
require "prawn"

RSpec.describe CvTextExtractor, type: :service do
  let(:candidate_profile) { create(:candidate_profile) }
  let(:document) { create(:candidate_document, candidate_profile: candidate_profile) }

  def build_valid_pdf_io(text: "Hello World")
    pdf = Prawn::Document.new
    pdf.text(text)
    io = StringIO.new(pdf.render)
    io.rewind
    io
  end

  def attach_file(document, io:, filename:, content_type:)
    document.file.attach(io: io, filename: filename, content_type: content_type)
    document.update_column(:content_type, content_type)
  end

  describe "#call" do
    context "when no file is attached" do
      it "raises UnsupportedFileTypeError" do
        document.file.detach
        expect { described_class.new(document).call }
          .to raise_error(CvTextExtractor::UnsupportedFileTypeError, "no file attached")
      end
    end

    context "with a valid PDF file" do
      before do
        attach_file(document,
          io: build_valid_pdf_io(text: "Rustam Zokirov Software Engineer"),
          filename: "cv.pdf",
          content_type: "application/pdf")
      end

      it "extracts the text content" do
        text = described_class.new(document).call
        expect(text).to include("Rustam Zokirov")
      end
    end

    context "with a corrupted PDF" do
      before do
        attach_file(document,
          io: StringIO.new("%PDF-1.4\nnot a real pdf body"),
          filename: "corrupted.pdf",
          content_type: "application/pdf")
      end

      it "raises CorruptedFileError" do
        expect { described_class.new(document).call }
          .to raise_error(CvTextExtractor::CorruptedFileError, /corrupted or malformed/)
      end

      it "logs the underlying error" do
        allow(Rails.logger).to receive(:error)
        begin
          described_class.new(document).call
        rescue CvTextExtractor::CorruptedFileError
          # expected
        end
        expect(Rails.logger).to have_received(:error).with(/malformed PDF/)
      end
    end

    context "with an unsupported file type" do
      before do
        attach_file(document,
          io: StringIO.new("plain text"),
          filename: "cv.txt",
          content_type: "text/plain")
      end

      it "raises UnsupportedFileTypeError" do
        expect { described_class.new(document).call }
          .to raise_error(CvTextExtractor::UnsupportedFileTypeError, /unsupported content type/)
      end
    end

    context "with a legacy .doc file" do
      before do
        attach_file(document,
          io: StringIO.new("legacy content"),
          filename: "cv.doc",
          content_type: "application/msword")
      end

      it "returns an empty string" do
        expect(described_class.new(document).call).to eq("")
      end

      it "logs a warning" do
        allow(Rails.logger).to receive(:warn)
        described_class.new(document).call
        expect(Rails.logger).to have_received(:warn).with(/legacy .doc format/)
      end
    end

    context "with a corrupted DOCX file" do
      before do
        attach_file(document,
          io: StringIO.new("not a real zip/docx structure"),
          filename: "corrupted.docx",
          content_type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document")
      end

      it "raises CorruptedFileError" do
        expect { described_class.new(document).call }
          .to raise_error(CvTextExtractor::CorruptedFileError, /corrupted or malformed/)
      end
    end
  end
end