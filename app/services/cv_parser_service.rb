class CvParserService
  # Platformaning fixed job categories (PRD 3.2)
  PLATFORM_JOB_CATEGORIES = %w[
    general_dentist dental_hygienist dental_assistant prevention_assistant
    paro_prevention_assistant orthodontic_assistant front_office
    practice_manager dental_technician specialist
  ].freeze

  EXTRACTION_SCHEMA = {
    first_name: "string yoki null",
    last_name: "string yoki null",
    email: "string yoki null",
    phone: "string yoki null",
    city: "string yoki null",
    country: "string yoki null",
    languages: [{ name: "string", level: "string yoki null - masalan B2, fluent, native" }],
    desired_job_function_guess: "string yoki null - PLATFORM_JOB_CATEGORIES ro'yxatidan eng yaqinini tanla",
    big_number: "string yoki null",
    big_status_guess: "string yoki null",
    years_of_combined_experience: "integer yoki null",
    educations: [{
      institution: "string yoki null",
      study: "string",
      city_country: "string yoki null",
      level: "string yoki null - MBO/HBO/Bachelor/Master/Doctor/Course",
      start_date: "YYYY-MM yoki null",
      end_date: "YYYY-MM yoki null"
    }],
    work_experiences: [{
      job_title: "string",
      company_name: "string",
      responsibilities: "string yoki null",
      start_date: "YYYY-MM yoki null",
      end_date: "YYYY-MM yoki null",
      current_job: "boolean"
    }],
    skills: ["string array"],
    professional_summary: "1-2 gapli xulosa yoki null"
  }.freeze

  class ParsingError < StandardError; end

  def initialize(document)
    @document = document
  end

  def call
    text = extract_text
    return empty_result if text.blank?

    raw_response = call_gemini(build_prompt(text))
    json_text = extract_json_text(raw_response)
    data = JSON.parse(json_text)

    symbolize_and_stringify_safely(data)
  rescue JSON::ParserError => e
    Rails.logger.error("[CvParserService] JSON parse error: #{e.message}")
    empty_result
  rescue ParsingError => e
    Rails.logger.error("[CvParserService] #{e.message}")
    empty_result
  end

  private

  # ---------- 1. Matnni faylni o'zidan olish ----------

  def extract_text
    CvTextExtractor.new(@document).call
  rescue => e
    Rails.logger.error("[CvParserService] text extraction failed: #{e.message}")
    nil
  end

  # ---------- 2. Gemini API'ga so'rov ----------

  def call_gemini(prompt)
    uri = URI("#{gemini_url}?key=#{api_key}")

    body = {
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: {
        response_mime_type: "application/json",
        thinking_config: { thinking_budget: 0 } # extraction uchun thinking kerak emas — tezroq va tejamkor
      }
    }

    response = Net::HTTP.post(uri, body.to_json, "Content-Type" => "application/json")

    unless response.is_a?(Net::HTTPSuccess)
      raise ParsingError, "Gemini API wrong response: #{response.code} #{response.body}"
    end

    JSON.parse(response.body)
  end

  def api_key
    ENV.fetch("GEMINI_API_KEY")
  end

  def gemini_url
    ENV.fetch("GEMINI_URL")
  end

  # ---------- 3. Javobdan matn ajratib olish ----------

  def extract_json_text(gemini_response)
    text = gemini_response.dig("candidates", 0, "content", "parts", 0, "text")
    raise ParsingError, "Gemini javobida matn topilmadi" if text.blank?

    # Ehtiyot chorasi: ba'zan model ```json bilan o'rab qaytarishi mumkin
    text.gsub(/\A```json\n?/, "").gsub(/```\z/, "").strip
  end

  # ---------- 4. Prompt qurish ----------

  def build_prompt(cv_text)
    <<~PROMPT
      Extract information from the CV text below and return it as JSON.

      RULES:
      - Only use information that is EXPLICITLY present in the text. Never invent anything.
      - If a field is not found, leave it as null or an empty array.
      - For "desired_job_function_guess", only pick from this list: #{PLATFORM_JOB_CATEGORIES.join(', ')}.
        If nothing matches clearly, leave it null.
      - Dates should be in YYYY-MM format (if only a year is given, use YYYY-01).
      - Include ALL work experiences found in the work_experiences array, not just the most recent one.
      - Return raw JSON only — no commentary, no markdown code fences.

      SCHEMA:
      #{JSON.pretty_generate(EXTRACTION_SCHEMA)}

      CV TEXT:
      ---
      #{cv_text}
      ---
    PROMPT
  end

  # ---------- 5. Xavfsiz normalizatsiya ----------

  # Gemini har doim schema'ga to'liq rioya qilmasligi mumkin (masalan
  # ba'zi kalitlar tushib qolishi), shuning uchun natijani empty_result
  # ustiga "deep merge" qilib, hech qachon kutilmagan struktura tufayli
  # keyingi kodda NoMethodError chiqmasligini ta'minlaymiz.
  def symbolize_and_stringify_safely(data)
    empty_result.merge(data) do |_key, default_val, parsed_val|
      parsed_val.nil? ? default_val : parsed_val
    end
  end

  def empty_result
    {
      "first_name" => nil,
      "last_name" => nil,
      "email" => nil,
      "phone" => nil,
      "city" => nil,
      "country" => nil,
      "languages" => [],
      "desired_job_function_guess" => nil,
      "big_number" => nil,
      "big_status_guess" => nil,
      "years_of_combined_experience" => nil,
      "educations" => [],
      "work_experiences" => [],
      "skills" => [],
      "professional_summary" => nil
    }
  end
end
