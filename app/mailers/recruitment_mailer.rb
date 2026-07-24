class RecruitmentMailer < ApplicationMailer
  default from: "onboarding@dentalplatform.com"

  def new_candidate(profile)
    @profile = profile
    @admin_url = candidate_profile_url(@profile, host: default_url_options[:host])

    mail(
      to: recruitment_team_email,
      subject: "New candidate profile completed: #{@profile.first_name} #{@profile.last_name}"
    )
  end

  private

  def recruitment_team_email
    ENV.fetch("RECRUITMENT_TEAM_EMAIL", "recruitment@dentalplatform.com")
  end
end