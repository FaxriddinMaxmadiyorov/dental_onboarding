class CandidateOnboardingsController < ApplicationController
  before_action :set_profile

  def upload
    # renders CV upload screen
    @document = @profile.candidate_documents.build(document_type: "cv")
  end

  def upload_cv
    unless params[:consent].present?
      @document = @profile.candidate_documents.build(document_type: "cv")
      flash.now[:alert] = "Davom etish uchun ma'lumotlarni qayta ishlashga rozilik berishingiz kerak."
      render :upload, status: :unprocessable_entity
      return
    end

    document = @profile.candidate_documents.build(document_type: "cv")
    document.file.attach(params.require(:candidate_document)[:file])
    document.original_filename = document.file.filename.to_s
    document.content_type = document.file.content_type
    document.file_size = document.file.byte_size

    if document.save
      @profile.update!(consent_given: true)
      ParseCandidateCvJob.perform_later(document.id)
      redirect_to status_candidate_onboarding_path
    else
      @document = document
      flash.now[:alert] = document.errors.full_messages.to_sentence
      render :upload, status: :unprocessable_entity
    end
  end

  def status
    document = @profile.latest_cv

    if document.completed?
      redirect_to edit_profile_candidate_onboarding_path
      return
    end

    render :status, locals: { document: document }
  end

  def edit_profile
    @profile.educations.build if @profile.educations.empty?
    @profile.work_experiences.build if @profile.work_experiences.empty?
  end

  def update
    if params[:candidate_profile][:remove_free_text_skill_ids].present?
      @profile.candidate_skills.where(id: params[:candidate_profile][:remove_free_text_skill_ids]).destroy_all
    end

    changed_fields = profile_params.keys & CandidateProfile::TRACKABLE_FIELDS
    @profile.cv_filled_fields -= changed_fields

    if @profile.update(profile_params.merge(onboarding_completed: true))
      @profile.validate(:final_save) # trigger stricter validations if desired
      NotifyRecruitmentTeamJob.perform_later(@profile.id)
      redirect_to root_path, notice: "Profil muvaffaqiyatli saqlandi"
    else
      render :edit_profile, status: :unprocessable_entity
    end
  end

  private

  def set_profile
    token = cookies.signed[:candidate_session]

    @profile = CandidateProfile.find_by(session_token: token) if token

    if @profile.nil?
      @profile = CandidateProfile.create!
      cookies.signed[:candidate_session] = {
        value: @profile.session_token,
        expires: 1.year,
        httponly: true
      }
    end
  end

  def profile_params
    params.require(:candidate_profile).permit(
      :first_name, :last_name, :email, :phone, :city, :country,
      :desired_job_function, :max_travel_time, :search_status, :reason_for_looking,
      :desired_salary, :desired_percentage, :average_daily_revenue,
      :big_status, :big_number, :years_of_experience,
      :available_from, :notice_period, :motivation, :internal_notes,
      :professional_summary, :consent_given,
      preferred_regions: [], transport_type: [], employment_type: [], available_days: [],
      educations_attributes: [:id, :institution, :study, :city_country, :level,
                               :start_date, :end_date, :_destroy],
      work_experiences_attributes: [:id, :job_title, :company_name, :responsibilities,
                                     :start_date, :end_date, :current_job, :_destroy],
      candidate_languages_attributes: [:id, :language_id, :level, :_destroy],
      skill_ids: []
    )
  end
end
