class CandidateOnboardingsController < ApplicationController
  before_action :redirect_admin_to_profiles, only: [:upload]
  before_action :set_profile

  def upload
    @document = @profile.candidate_documents.build(document_type: "cv")
  end

  def upload_cv
    unless params[:consent].present?
      @document = @profile.candidate_documents.build(document_type: "cv")
      flash.now[:alert] = "To continue, please provide consent."
      render :upload, status: :unprocessable_entity
      return
    end

    document = @profile.candidate_documents.build(document_type: "cv")

    begin
      document.file.attach(params.require(:candidate_document)[:file])
    rescue ActionController::ParameterMissing
      @document = document
      flash.now[:alert] = "Please select a file to upload."
      render :upload, status: :unprocessable_entity
      return
    end

    document.original_filename = document.file.filename.to_s
    document.content_type = document.file.content_type
    document.file_size = document.file.byte_size

    if document.save
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
    if profile_params[:remove_free_text_skill_ids].present?
      @profile.candidate_skills.where(id: profile_params[:remove_free_text_skill_ids]).destroy_all
    end

    changed_fields = profile_params.keys & CandidateProfile::TRACKABLE_FIELDS
    @profile.cv_filled_fields -= changed_fields

    @profile.assign_attributes(profile_params.merge(onboarding_completed: true))

    if @profile.valid?(:final_save) && @profile.save
      NotifyRecruitmentTeamJob.perform_later(@profile.id) if defined?(NotifyRecruitmentTeamJob)
      redirect_to onboarded_candidate_onboarding_path, notice: "Profile was successfully saved."
    else
      render :edit_profile, status: :unprocessable_entity
    end
  end

  def onboarded
    cookies.delete(:candidate_session)
  end

  def profile
  end

  private

  def redirect_admin_to_profiles
    redirect_to candidate_profiles_path if Current.user.admin?
  end

  def set_profile
    @profile = CandidateProfile.find_or_create_by!(user_id: Current.user.id)
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
      skill_ids: [], remove_free_text_skill_ids: []
    )
  end
end
