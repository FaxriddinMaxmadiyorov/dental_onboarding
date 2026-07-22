class NotifyRecruitmentTeamJob < ApplicationJob
  def perform(profile_id)
    profile = CandidateProfile.find(profile_id)
    RecruitmentMailer.new_candidate(profile).deliver_later
  end
end
