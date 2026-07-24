class CandidateProfilesController < ApplicationController
  before_action :set_profile, only: %i[show edit update destroy]

  def index
    authorize CandidateProfile

    @profiles = CandidateProfile.where(onboarding_completed: true).order(created_at: :desc)
  end

  def show
    authorize @profile
  end

  def edit
    authorize @profile
  end

  # app/controllers/candidate_profiles_controller.rb
  def update
    if profile_params[:remove_free_text_skill_ids].present?
      @profile.candidate_skills.where(id: profile_params[:remove_free_text_skill_ids]).destroy_all
    end

    if @profile.valid?(:final_save) && @profile.save
      redirect_to candidate_profiles_path, notice: "Profile was successfully saved."
    else
      render :edit_profile, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @profile

    @profile.destroy
    redirect_to candidate_profiles_url, notice: "Profile was successfully deleted."
  end

  private

  def set_profile
    @profile = CandidateProfile.find(params[:id])
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
