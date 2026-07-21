class CandidateDocument < ApplicationRecord
  belongs_to :candidate_profile
  has_one_attached :file

  ALLOWED_TYPES = %w[application/pdf application/msword
    application/vnd.openxmlformats-officedocument.wordprocessingml.document].freeze
  MAX_SIZE = (ENV["CV_MAX_SIZE_MB"] || "25").to_i.megabytes

  validates :file, presence: true
  validate :acceptable_file

  private

  def acceptable_file
    return unless file.attached?

    unless ALLOWED_TYPES.include?(file.content_type)
      errors.add(:file, "PDF, DOC yoki DOCX bo'lishi kerak")
    end
    if file.byte_size > MAX_SIZE
      errors.add(:file, "juda katta (max #{MAX_SIZE / 1.megabyte}MB)")
    end
  end
end
