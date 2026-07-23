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

  def update
    authorize @profile

    if @profile.update(profile_params)
      redirect_to @profile, notice: "Profile was successfully updated."
    else
      render :edit
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
end
