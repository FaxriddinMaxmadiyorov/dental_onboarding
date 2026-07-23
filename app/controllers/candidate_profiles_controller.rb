class CandidateProfilesController < BaseController
  def index
    @profiles = CandidateProfile.where(onboarding_completed: true).order(created_at: :desc)
  end

  def show
    @profile = CandidateProfile.find(params[:id])
  end
end
