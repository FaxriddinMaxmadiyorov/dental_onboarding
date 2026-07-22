class ProfilePrefillService
  def initialize(profile, parsed_data)
    @profile = profile
    @data = parsed_data
    @filled_fields = []
  end

  def call
    ActiveRecord::Base.transaction do
      # CV qayta yuklanganda avvalgi CV'dan kelgan yozuvlarni tozalaymiz
      # (candidate qo'lda qo'shgan yozuvlarga tegmaymiz — ular from_cv: false).
      @profile.educations.where(from_cv: true).destroy_all
      @profile.work_experiences.where(from_cv: true).destroy_all

      fill_personal_details
      fill_job_preferences
      fill_employment_fields
      fill_educations
      fill_work_experiences
      fill_skills
      fill_languages

      @profile.cv_filled_fields = (@profile.cv_filled_fields + @filled_fields).uniq

      @profile.save!
    end
  end

  private

  # Faqat bo'sh maydonlarni to'ldiramiz — mavjud qiymatlarni bosib
  # yozmaymiz (candidate hali forma to'ldirmagan bo'lishi mumkin).
  def fill_personal_details
    assign_if_blank(:first_name, @data["first_name"])
    assign_if_blank(:last_name, @data["last_name"])
    assign_if_blank(:phone, @data["phone"])
    assign_if_blank(:city, @data["city"])
    assign_if_blank(:country, @data["country"])
  end

  def fill_job_preferences
    # "Partly" — faqat taxmin sifatida, candidate baribir tasdiqlashi kerak.
    assign_if_blank(:desired_job_function, @data["desired_job_function_guess"])
  end

  def fill_employment_fields
    assign_if_blank(:big_number, @data["big_number"])
    assign_if_blank(:years_of_experience, @data["years_of_combined_experience"])
    assign_if_blank(:professional_summary, @data["professional_summary"])
  end

  def assign_if_blank(field, value)
    return if value.blank?
    return if @profile.public_send(field).present?

    @profile.public_send("#{field}=", value)
    @filled_fields << field.to_s
  end

  def fill_educations
    Array(@data["educations"]).each do |edu|
      next if edu["study"].blank?

      @profile.educations.create!(
        institution: edu["institution"],
        study: edu["study"],
        city_country: edu["city_country"],
        level: edu["level"],
        start_date: edu["start_date"],
        end_date: edu["end_date"],
        from_cv: true
      )
    end
  end

  def fill_work_experiences
    Array(@data["work_experiences"]).each do |we|
      next if we["job_title"].blank? && we["company_name"].blank?

      @profile.work_experiences.create!(
        job_title: we["job_title"],
        company_name: we["company_name"],
        responsibilities: we["responsibilities"],
        start_date: we["start_date"],
        end_date: we["end_date"],
        current_job: we["current_job"] || false,
        from_cv: true
      )
    end
  end

  def fill_skills
    Array(@data["skills"]).each do |skill_name|
      next if skill_name.blank?

      skill = Skill.find_by("lower(name) = ?", skill_name.to_s.downcase.strip)

      if skill
        @profile.candidate_skills.find_or_create_by!(skill: skill)
      else
        @profile.candidate_skills.find_or_create_by!(free_text_suggestion: skill_name.strip)
      end
    end
  end

  def fill_languages
    Array(@data["languages"]).each do |lang|
      next if lang["name"].blank?

      language = Language.find_or_create_by!(name: lang["name"].strip.titleize)
      @profile.candidate_languages.find_or_create_by!(language: language) do |cl|
        cl.level = lang["level"]
      end
    end
  end
end
