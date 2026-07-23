# Preview all emails at http://localhost:3000/rails/mailers/recruitment_mailer
class RecruitmentMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/recruitment_mailer/new_candidate
  def new_candidate
    RecruitmentMailer.new_candidate(CandidateProfile.first)
  end
end
