class CandidateOnboardingsController < ApplicationController
  before_action :set_profile

  def upload
    # renders CV upload screen
  end

  def upload_cv
    document = @profile.candidate_documents.build(document_type: "cv")
    document.file.attach(params.require(:candidate_document)[:file])
    document.original_filename = document.file.filename.to_s
    document.content_type = document.file.content_type
    document.file_size = document.file.byte_size

    if document.save
      ParseCandidateCvJob.perform_later(document.id)
      redirect_to status_candidate_onboarding_path
    else
      flash.now[:alert] = document.errors.full_messages.to_sentence
      render :upload, status: :unprocessable_entity
    end
  end

  def status
    document = @profile.latest_cv
    respond_to do |format|
      format.html { render :status, locals: { document: document } }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "cv_status",
          partial: "candidate_onboardings/cv_status",
          locals: { document: document }
        )
      end
    end
  end

  def edit_profile
    @profile.educations.build if @profile.educations.empty?
    @profile.work_experiences.build if @profile.work_experiences.empty?
  end

  def update
    if @profile.update(profile_params.merge(onboarding_completed: true))
      @profile.validate(:final_save) # trigger stricter validations if desired
      NotifyRecruitmentTeamJob.perform_later(@profile.id) if defined?(NotifyRecruitmentTeamJob)
      redirect_to root_path, notice: "Profil muvaffaqiyatli saqlandi"
    else
      render :edit_profile, status: :unprocessable_entity
    end
  end

  private

  def set_profile
    @profile = current_user.candidate_profile || current_user.create_candidate_profile
  end

  def profile_params
    params.require(:candidate_profile).permit(
      :first_name, :last_name, :phone, :city, :country,
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
