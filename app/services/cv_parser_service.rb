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
    sleep 5
  #   text = extract_text
  #   return empty_result if text.blank?

  #   raw_response = call_gemini(build_prompt(text))
  #   json_text = extract_json_text(raw_response)
  #   data = JSON.parse(json_text)

  #   symbolize_and_stringify_safely(data)
  # rescue JSON::ParserError => e
  #   Rails.logger.error("[CvParserService] JSON parse error: #{e.message}")
  #   empty_result
  # rescue ParsingError => e
  #   Rails.logger.error("[CvParserService] #{e.message}")
  #   empty_result
  {"first_name"=>"Fakhriddin",
 "last_name"=>"Makhmadiyorov",
 "email"=>"makhmadiyorovfakhriddindaad@gmail.com",
 "phone"=>nil,
 "city"=>nil,
 "country"=>nil,
 "languages"=>[],
 "desired_job_function_guess"=>nil,
 "big_number"=>nil,
 "big_status_guess"=>nil,
 "years_of_combined_experience"=>7,
 "educations"=>[{"institution"=>"Tashkent University of Information Technologies", "study"=>"Computer Science", "city_country"=>nil, "level"=>"Bachelor", "start_date"=>nil, "end_date"=>nil}],
 "work_experiences"=>
  [{"job_title"=>"Senior Software Engineer",
    "company_name"=>"The Access Group, theaccessgroup.com (via Gotoinc)",
    "responsibilities"=>
     "Managed Capistrano deployments across a 4-server AWS infrastructure with role-separated nodes: web, webhooks, and Sidekiq worker, each with tuned Puma worker configurations per workload type.\nMigrated search infrastructure from Algolia to self-hosted Elasticsearch, reducing monthly costs by $1,500 while maintaining search performance and improving query flexibility.\nImproved data preprocessing workflows (caching, batching), resulting in a 10 % reduction in processing time.\nIdentified and resolved N+1 patterns and rewrote critical queries using EXPLAIN ANALYZE, achieving up to 28x performance improvement on high-traffic endpoints.\nDeveloped custom algorithms to import and synchronize client data between different product parts across a multi-tenant SaaS platform, optimizing data management.\nContributed to Rails and Vue.js major version migration strategies, analyzing breaking changes and coordinating incremental rollout to minimize regression risk across the codebase.\nImplemented Flipper feature toggles to enable safe, incremental feature rollouts across a multi-tenant enterprise platform, minimizing regression risk during major version migrations.\nReviewed 400+ pull requests, enforcing code quality and catching regressions across the codebase.",
    "start_date"=>"2024-08",
    "end_date"=>nil,
    "current_job"=>true},
   {"job_title"=>"Software Engineer",
    "company_name"=>"Uzrek Payment Systems, upay.net",
    "responsibilities"=>
     "Designed and developed a robust and secure peer-to-peer (P2P) transaction system to facilitate direct transfers between users (Machnet, Stripe, PayPal)\nIdentified and resolved server issues, specifically targeting performance bottlenecks, to minimize downtime and disruptions to testing activities, resulting in a significant 25 % increase in team performance\nParticipated in interview panels and debrief meetings to share insights, evaluate candidates’ qualifications, and make hiring recommendations\nDesigned and implemented automated build, test, and deployment pipelines using GitLab CI/CD\nMonitored application performance and errors with Datadog and Sentry, tracking down bottlenecks and fixing them through query optimization and code refactoring.\nDeveloped a chat microservice using Action Cable and Sidekiq, allowing real-time communication between users\nResolved a critical race condition issue by implementing database-level locking, which was causing data inconsistencies and potential revenue loss.\nContributed to decomposing a monolithic payment application into independent services, isolating domain logic for P2P transfers, chat, and notification systems to improve scalability and maintainability.",
    "start_date"=>"2022-05",
    "end_date"=>"2024-08",
    "current_job"=>false},
   {"job_title"=>"Software Engineer",
    "company_name"=>"upaytravels",
    "responsibilities"=>
     "Managed and led a 3-person team building the Upay Travels CRM, handled task distribution, code reviews, and delivery.\nDesigned and developed the CRM system architecture tailored for internal use by airline operators, focusing on scalability and user efficiency\nCreated an admin dashboard to monitor key metrics and performance indicators, providing real-time insights into system performance and operational efficiency\nDesigned and implemented frontend functionalities using HTML/CSS/JS to ensure an intuitive and responsive user interface.\nContainerized the application using Docker, facilitating consistent development and production environments.\nApplied rate limiting and IP blacklisting to mitigate abuse, safeguard application integrity, and protect against common attacks.\nMentored junior developers, providing guidance on best practices and helping them grow professionally.",
    "start_date"=>"2022-05",
    "end_date"=>"2024-08",
    "current_job"=>false},
   {"job_title"=>"Software Engineer",
    "company_name"=>"DK-KLUB",
    "responsibilities"=>
     "Led the development and maintenance of MVP for a comprehensive online travel agency currently serving over 15,000 users\nIntegrated 3 payment systems using REST, JSON-RPC and SOAP protocols, covered with unit tests\nDeveloped REST API for a new mobile application that increased bookings by 25%\nUpgraded Rails version from 6.x to 7.x\nOptimized and rewrote complex SQL and ActiveRecord queries for data analysis and reporting, resolving N+1 problems and improving page loading times by 30%\nLeveraged knowledge in Git, Linux, Docker, OOP principles, relational databases and programmed using Ruby on Rails",
    "start_date"=>"2021-09",
    "end_date"=>"2022-04",
    "current_job"=>false},
   {"job_title"=>"Software Engineer",
    "company_name"=>"DK-KLUB / EduCRM",
    "responsibilities"=>
     "Designed and maintained a multi-tenant SaaS CRM for educational centers, with isolated tenant data and configurable business workflows.\nBuilt core academic modules covering admissions, enrollment, course management, class scheduling, attendance, and grading.\nDeveloped a full tuition management system including invoicing, payment tracking, discounts, and debt management, with financial reporting.\nImplemented fine-grained role-based access control (RBAC) and RESTful APIs, integrating third-party SMS/email notification services.\nAutomated recurring workflows (notifications, report generation, scheduled jobs) with Sidekiq, and optimized PostgreSQL queries to reduce response times for high-traffic operations.\nBuilt reporting dashboards surfacing student performance, attendance, and revenue metrics, backed by comprehensive RSpec test coverage and CI/CD workflows.",
    "start_date"=>"2020-04",
    "end_date"=>"2021-09",
    "current_job"=>false}],
 "skills"=>
  ["Ruby",
   "Go",
   "Ruby on Rails",
   "JavaScript",
   "Vue.js",
   "React",
   "HTML/CSS",
   "PostgreSQL",
   "MongoDB",
   "Redis",
   "Elasticsearch",
   "AWS",
   "Docker",
   "NGINX",
   "GitLab/GitHub CI/CD",
   "RabbitMQ",
   "Sidekiq",
   "Capistrano",
   "REST",
   "GraphQL",
   "JSON-RPC",
   "SOAP",
   "Action Cable",
   "WebSockets",
   "RSpec",
   "Cypress"],
 "professional_summary"=>
  "Backend-focused Software Engineer with 7 years of commercial experience building scalable Ruby on Rails applications for fintech, SaaS, travel, and education platforms. Experienced in system design, distributed backend architecture, payment systems integration, PostgreSQL performance optimization, and scalable application development."}
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
