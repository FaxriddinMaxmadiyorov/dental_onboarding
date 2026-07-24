class CvParserService
  PLATFORM_JOB_CATEGORIES = CandidateProfile::JOB_FUNCTIONS.values.freeze

  EXTRACTION_SCHEMA = {
    first_name: "string or null",
    last_name: "string or null",
    email: "string or null",
    phone: "string or null",
    city: "string or null",
    country: "string or null",
    languages: [{ name: "string", level: "string or null - ex B2, fluent, native" }],
    desired_job_function_guess: "string or null - choose guesses from PLATFORM_JOB_CATEGORIES",
    big_number: "string or null",
    big_status_guess: "string or null",
    years_of_combined_experience: "integer or null",
    educations: [{
      institution: "string or null",
      study: "string",
      city_country: "string or null",
      level: "string or null - MBO/HBO/Bachelor/Master/Doctor/Course",
      start_date: "YYYY-MM or null",
      end_date: "YYYY-MM or null"
    }],
    work_experiences: [{
      job_title: "string",
      company_name: "string",
      responsibilities: "string or null",
      start_date: "YYYY-MM or null",
      end_date: "YYYY-MM or null",
      current_job: "boolean"
    }],
    skills: ["string array"],
    professional_summary: "1-2 sentence summary or null"
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
    raise
  end

  private

  # ---------- 1. Retrieve text from document ----------

  def extract_text
    CvTextExtractor.new(@document).call
  rescue CvTextExtractor::CorruptedFileError => e
    raise ParsingError, "CV file could not be read: #{e.message}"
  rescue => e
    Rails.logger.error("[CvParserService] text extraction failed: #{e.message}")
    raise ParsingError, "CV file could not be processed"
  end

  # ---------- 2. Request to Gemini API ----------

  def call_gemini(prompt)
    uri = URI("#{gemini_url}?key=#{api_key}")

    body = {
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: {
        response_mime_type: "application/json"
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

  # ---------- 3. Response from Gemini ----------

  def extract_json_text(gemini_response)
    text = gemini_response.dig("candidates", 0, "content", "parts", 0, "text")
    raise ParsingError, "Gemini response does not contain text" if text.blank?

    # Ehtiyot chorasi: ba'zan model ```json bilan o'rab qaytarishi mumkin
    text.gsub(/\A```json\n?/, "").gsub(/```\z/, "").strip
  end

  # ---------- 4. Prompt qurish ----------

  def build_prompt(cv_text)
    <<~PROMPT
      You are extracting structured candidate data from a CV for a dental recruitment
      platform. The CV may be written in English or Dutch — read and understand both
      languages fluently.

      CRITICAL RULES:
      - Only use information that is EXPLICITLY present in the text. NEVER invent, guess,
        or infer information that is not clearly stated.
      - If a field is not found in the CV, leave it as null (or an empty array for list
        fields). An empty or missing field is always preferable to a guessed one.
      - Every extracted value must map to the correct field in the schema below — do not
        mix data between fields (e.g. do not put a company name in job_title).
      - For "desired_job_function_guess", only pick from this list: #{PLATFORM_JOB_CATEGORIES.join(', ')}.
        If nothing matches clearly, leave it null. Do not force a match.
      - Regardless of the CV's source language, return extracted text values in English
        where they describe skills, job titles, or field labels — except for proper nouns
        (person names, company names, institution names, place names), which must stay
        exactly as written in the original CV.
      - Dates should be in YYYY-MM format (if only a year is given, use YYYY-01).
      - Include ALL work experiences found in the work_experiences array, not just the
        most recent one.
      - Return raw JSON only — no commentary, no markdown code fences, no explanations.

      SCHEMA:
      #{JSON.pretty_generate(EXTRACTION_SCHEMA)}

      CV TEXT:
      ---
      #{cv_text}
      ---
    PROMPT
  end

  # ---------- 5. Safe Normalization ----------

  # Given the parsed data, ensure all expected fields are present and have the correct types.
  # If a field is missing, fill it with null (or an empty array for list fields).
  # If a field is present but has a null value, keep it as null.
  # This ensures that the final output always conforms to the expected schema.
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
