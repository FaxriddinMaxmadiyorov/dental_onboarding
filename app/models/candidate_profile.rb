class CandidateProfile < ApplicationRecord
  belongs_to :user

  has_many :candidate_documents, dependent: :destroy
  has_many :educations, dependent: :destroy
  has_many :work_experiences, dependent: :destroy
  has_many :candidate_skills, dependent: :destroy
  has_many :skills, through: :candidate_skills
  has_many :candidate_languages, dependent: :destroy
  has_many :languages, through: :candidate_languages

  accepts_nested_attributes_for :educations, allow_destroy: true,
    reject_if: proc { |attrs| attrs["study"].blank? }
  accepts_nested_attributes_for :work_experiences, allow_destroy: true,
    reject_if: proc { |attrs| attrs["job_title"].blank? && attrs["company_name"].blank? }
  accepts_nested_attributes_for :candidate_languages, allow_destroy: true

  SEARCH_STATUSES = %w[active passive inactive].freeze
  BIG_STATUSES = %w[registered in_progress under_supervision not_applicable].freeze
  BIG_FUNCTIONS = %w[general_dentist dental_hygienist specialist].freeze
  EMPLOYED_TYPES = %w[employed].freeze
  SELF_EMPLOYED_TYPES = %w[self_employed percentage_based].freeze
  AVERAGE_REVENUE_FUNCTIONS = %w[general_dentist dental_hygienist specialist prevention_assistant].freeze

  JOB_FUNCTIONS = {
    "General Dentist" => "general_dentist",
    "Dental Hygienist" => "dental_hygienist",
    "Dental Assistant" => "dental_assistant",
    "Prevention Assistant" => "prevention_assistant",
    "Paro-Prevention Assistant" => "paro_prevention_assistant",
    "Orthodontic Assistant" => "orthodontic_assistant",
    "Front-Office / Receptionist" => "front_office",
    "Practice Manager" => "practice_manager",
    "Dental Technician" => "dental_technician",
    "Specialist" => "specialist"
  }.freeze

  JOB_FUNCTION_TO_SKILL_GROUP = {
    "general_dentist" => "dentist",
    "specialist" => "dentist",
    "dental_hygienist" => "dental_hygienist",
    "dental_assistant" => "dental_assistant",
    "prevention_assistant" => "dental_assistant",
    "paro_prevention_assistant" => "dental_assistant",
    "orthodontic_assistant" => "dental_assistant",
    "front_office" => "front_office",
    "practice_manager" => "practice_manager",
    "dental_technician" => "dental_technician"
  }.freeze

  validates :first_name, :last_name, :email_for_validation_placeholder, presence: true, on: :final_save
  # Note: email lives on User; validate via delegation if needed.

  validates :city, presence: true, on: :final_save
  validates :desired_job_function, presence: true, on: :final_save
  validates :max_travel_time, presence: true, numericality: true, on: :final_save
  validates :years_of_experience, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :desired_percentage, numericality: { in: 0..100 }, allow_nil: true
  validates :big_number, presence: true, if: -> { big_status == "registered" }, on: :final_save

  def shows_big_fields?
    BIG_FUNCTIONS.include?(desired_job_function)
  end

  def shows_salary_field?
    (employment_type || []).any? { |t| EMPLOYED_TYPES.include?(t) }
  end

  def shows_percentage_field?
    (employment_type || []).any? { |t| SELF_EMPLOYED_TYPES.include?(t) }
  end

  def latest_cv
    candidate_documents.where(document_type: "cv").order(created_at: :desc).first
  end

  def field_from_cv?(field_name)
    cv_filled_fields.include?(field_name.to_s)
  end

  def shows_average_revenue_field?
    AVERAGE_REVENUE_FUNCTIONS.include?(desired_job_function)
  end
end
