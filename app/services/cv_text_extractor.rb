require "pdf-reader"

# Extracts raw text from an uploaded CandidateDocument (PDF, DOC, or DOCX).
#
# Usage:
#   CvTextExtractor.new(candidate_document).call
#   # => String (may be blank if the file has no extractable text)
class CvTextExtractor
  SUPPORTED_TYPES = %w[
    application/pdf
    application/msword
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
  ].freeze

  class UnsupportedFileTypeError < StandardError; end
  class CorruptedFileError < StandardError; end

  def initialize(document)
    @document = document
  end

  def call
    raise UnsupportedFileTypeError, "no file attached" unless @document.file.attached?

    case @document.content_type
    when "application/pdf"
      extract_pdf
    when "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      extract_docx
    when "application/msword"
      # Legacy .doc format — .docx uchun ishlatiladigan gem buni o'qiy olmaydi.
      # Amaliyotda .doc juda kam uchraydi; hozircha bo'sh matn qaytaramiz,
      # parser esa keyin "manual continue" oqimiga tushadi.
      Rails.logger.warn("[CvTextExtractor] legacy .doc format is not supported for text extraction")
      ""
    else
      raise UnsupportedFileTypeError, "unsupported content type: #{@document.content_type}"
    end
  end

  private

  def extract_pdf
    @document.file.blob.open do |tempfile|
      reader = PDF::Reader.new(tempfile.path)
      reader.pages.map(&:text).join("\n")
    end

    raise CorruptedFileError, "PDF contains no readable text" if text.blank?

    text
  rescue PDF::Reader::MalformedPDFError => e
    Rails.logger.error("[CvTextExtractor] malformed PDF: #{e.message}")
    raise CorruptedFileError, "PDF file is corrupted or malformed"
  end

  def extract_docx
    require "docx"
    text = @document.file.blob.open do |tempfile|
      Docx::Document.open(tempfile.path).paragraphs.map(&:text).join("\n")
    end

    raise CorruptedFileError, "DOCX contains no readable text" if text.blank?

    text
  rescue Docx::Errors::MalformedDocumentError, Zip::Error => e
    Rails.logger.error("[CvTextExtractor] corrupted docx: #{e.message}")
    raise CorruptedFileError, "DOCX file is corrupted or malformed"
  end
end
