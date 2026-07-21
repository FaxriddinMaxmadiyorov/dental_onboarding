class CvParserService
  def initialize(document)
    @document = document
  end

  def call
    # TODO: haqiqiy parsing logikasi
    # Natija shu strukturada bo'lishi kerak — pastdagi
    # ProfilePrefillService shu formatni kutadi:
    {
      "first_name" => nil,
      "last_name" => nil,
      "phone" => nil,
      "city" => nil,
      "country" => nil,
      "languages" => [],            # [{ "name" => "English", "level" => "fluent" }]
      "job_function" => nil,
      "educations" => [],           # [{ "institution" => ..., "study" => ..., ... }]
      "work_experiences" => [],     # [{ "job_title" => ..., "company_name" => ..., ... }]
      "skills" => [],               # ["endodontics", ...]
      "years_of_experience" => nil,
      "professional_summary" => nil
    }
  end
end
