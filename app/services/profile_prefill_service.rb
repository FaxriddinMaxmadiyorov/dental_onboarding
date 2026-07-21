class ProfilePrefillService
  def initialize(profile, parsed_data)
    @profile = profile
    @data = parsed_data
  end

  def call
    ActiveRecord::Base.transaction do
      # Faqat bo'sh maydonlarni to'ldiramiz — mavjud qiymatlarni bosib
      # yozmaymiz (candidate hali forma to'ldirmagan bo'lishi mumkin).
      @profile.first_name ||= @data["first_name"]
      @profile.last_name  ||= @data["last_name"]
      @profile.phone      ||= @data["phone"]
      @profile.city       ||= @data["city"]
      @profile.country    ||= @data["country"]
      @profile.years_of_experience ||= @data["years_of_experience"]
      @profile.professional_summary ||= @data["professional_summary"]
      @profile.save!

      Array(@data["educations"]).each do |edu|
        @profile.educations.create!(
          institution: edu["institution"], study: edu["study"],
          city_country: edu["city_country"], level: edu["level"],
          start_date: edu["start_date"], end_date: edu["end_date"],
          from_cv: true
        )
      end

      Array(@data["work_experiences"]).each do |we|
        @profile.work_experiences.create!(
          job_title: we["job_title"], company_name: we["company_name"],
          responsibilities: we["responsibilities"],
          start_date: we["start_date"], end_date: we["end_date"],
          current_job: we["current_job"] || false, from_cv: true
        )
      end

      Array(@data["skills"]).each do |skill_name|
        skill = Skill.find_by("lower(name) = ?", skill_name.to_s.downcase)
        if skill
          @profile.candidate_skills.find_or_create_by!(skill: skill)
        else
          @profile.candidate_skills.create!(free_text_suggestion: skill_name)
        end
      end
    end
  end
end
