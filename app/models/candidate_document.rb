class CandidateDocument < ApplicationRecord
  belongs_to :candidate_profile
  has_one_attached :file

  ALLOWED_TYPES = %w[application/pdf application/msword
    application/vnd.openxmlformats-officedocument.wordprocessingml.document].freeze
  MAX_SIZE = ENV.fetch("CV_MAX_SIZE_MB", "25").to_i

  validates :file, presence: true
  validate :acceptable_file

  enum :parsing_status, {
    pending: "pending",
    processing: "processing",
    completed: "completed",
    failed: "failed"
  }, default: :pending

  private

  def acceptable_file
    return unless file.attached?

    unless ALLOWED_TYPES.include?(file.content_type)
      errors.add(:file, "must be a PDF, DOC, or DOCX file")
    end
    if file.byte_size > MAX_SIZE * 1.megabyte
      errors.add(:file, "is too large (max #{MAX_SIZE} MB)")
    end
  end
end
