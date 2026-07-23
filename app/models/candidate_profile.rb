class CandidateProfile < ApplicationRecord
  before_create :generate_session_token

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
  TRACKABLE_FIELDS = %w[
    first_name last_name email phone city country
    desired_job_function big_number years_of_experience
    professional_summary
  ].freeze

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

  validates :first_name, :last_name, :email, presence: true, on: :final_save
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, on: :final_save
  validates :phone, format: { with: /\A\+?[0-9\s\-\(\)]{7,20}\z/, message: "must be a valid phone number" }, on: :final_save
  validates :city, presence: true, on: :final_save
  validates :desired_job_function, presence: true, on: :final_save
  validates :max_travel_time, presence: true, numericality: true, on: :final_save
  validates :search_status, inclusion: { in: SEARCH_STATUSES }, on: :final_save
  validates :years_of_experience, numericality: { greater_than_or_equal_to: 0 }, on: :final_save
  validates :big_number, presence: true, if: -> { big_status == "registered" }, on: :final_save
  validates :average_daily_revenue, numericality: true, if: :shows_average_revenue_field?, on: :final_save
  validates :desired_salary, presence: true, numericality: { greater_than: 0 }, if: :shows_salary_field?, on: :final_save
  validates :desired_percentage, presence: true, numericality: { in: 0..100 }, if: :shows_percentage_field?, on: :final_save
  validates :available_from, presence: true, on: :final_save

  validate :preferred_regions_present, on: :final_save
  validate :employment_type_present, on: :final_save
  validate :available_days_present, on: :final_save
  validate :available_from_not_in_past, on: :final_save

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

  private

  def generate_session_token
    self.session_token = SecureRandom.urlsafe_base64(32)
  end

  def preferred_regions_present
    if preferred_regions.blank?
      errors.add(:preferred_regions, "Please select at least one preferred region")
    end
  end

  def employment_type_present
    if employment_type.blank?
      errors.add(:employment_type, "Please select at least one employment type")
    end
  end

  def available_days_present
    if available_days.blank?
      errors.add(:available_days, "Please select at least one available day")
    end
  end

  def available_from_not_in_past
    return if available_from.blank?
    errors.add(:available_from, "can't be in the past") if available_from < Date.current
  end
end
