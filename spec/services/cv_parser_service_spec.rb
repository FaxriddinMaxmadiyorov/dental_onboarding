require "rails_helper"

RSpec.describe CvParserService, type: :service do
  let(:candidate_profile) { create(:candidate_profile) }
  let(:document) { create(:candidate_document, candidate_profile: candidate_profile) }
  let(:service) { described_class.new(document) }

  let(:valid_gemini_response_body) do
    {
      "candidates" => [
        {
          "content" => {
            "parts" => [
              {
                "text" => {
                  "first_name" => "Rustam",
                  "last_name" => "Zokirov",
                  "email" => "rustam@example.com",
                  "phone" => nil,
                  "city" => nil,
                  "country" => nil,
                  "languages" => [],
                  "desired_job_function_guess" => nil,
                  "big_number" => nil,
                  "big_status_guess" => nil,
                  "years_of_combined_experience" => 4,
                  "educations" => [
                    { "institution" => "Test University", "study" => "Computer Science",
                      "city_country" => nil, "level" => "Bachelor", "start_date" => nil, "end_date" => nil }
                  ],
                  "work_experiences" => [
                    { "job_title" => "Engineer", "company_name" => "Acme",
                      "responsibilities" => nil, "start_date" => "2020-01", "end_date" => nil, "current_job" => true }
                  ],
                  "skills" => ["Python", "Ruby"],
                  "professional_summary" => "Experienced engineer."
                }.to_json
              }
            ]
          }
        }
      ]
    }.to_json
  end

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("GEMINI_API_KEY").and_return("fake-key")
    allow(ENV).to receive(:fetch).with("GEMINI_URL").and_return("https://fake-gemini-url.test/generate")
  end

  describe "#call" do
    context "when text extraction succeeds and Gemini returns valid data" do
      before do
        allow(CvTextExtractor).to receive(:new).with(document).and_return(
          instance_double(CvTextExtractor, call: "Rustam Zokirov's CV text content")
        )

        http_response = instance_double(Net::HTTPSuccess, body: valid_gemini_response_body)
        allow(http_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        allow(Net::HTTP).to receive(:post).and_return(http_response)
      end

      it "returns a hash with all extracted fields" do
        result = service.call

        expect(result["first_name"]).to eq("Rustam")
        expect(result["last_name"]).to eq("Zokirov")
        expect(result["email"]).to eq("rustam@example.com")
        expect(result["years_of_combined_experience"]).to eq(4)
      end

      it "includes parsed educations" do
        result = service.call
        expect(result["educations"]).to be_an(Array)
        expect(result["educations"].first["study"]).to eq("Computer Science")
      end

      it "includes parsed work_experiences" do
        result = service.call
        expect(result["work_experiences"].first["job_title"]).to eq("Engineer")
      end

      it "includes parsed skills" do
        result = service.call
        expect(result["skills"]).to contain_exactly("Python", "Ruby")
      end

      it "fills missing fields with defaults from empty_result" do
        result = service.call
        expect(result["phone"]).to be_nil
        expect(result["languages"]).to eq([])
      end
    end

    context "when the CV text is blank (e.g. unsupported .doc file)" do
      before do
        allow(CvTextExtractor).to receive(:new).with(document).and_return(
          instance_double(CvTextExtractor, call: "")
        )
      end

      it "returns the empty_result without calling Gemini" do
        expect(Net::HTTP).not_to receive(:post)
        result = service.call
        expect(result["first_name"]).to be_nil
        expect(result["educations"]).to eq([])
      end
    end

    context "when the file is corrupted" do
      before do
        allow(CvTextExtractor).to receive(:new).with(document).and_return(
          instance_double(CvTextExtractor).tap do |extractor|
            allow(extractor).to receive(:call).and_raise(
              CvTextExtractor::CorruptedFileError, "PDF file is corrupted or malformed"
            )
          end
        )
      end

      it "raises a ParsingError" do
        expect { service.call }.to raise_error(CvParserService::ParsingError, /CV file could not be read/)
      end
    end

    context "when text extraction fails with an unexpected error" do
      before do
        allow(CvTextExtractor).to receive(:new).with(document).and_return(
          instance_double(CvTextExtractor).tap do |extractor|
            allow(extractor).to receive(:call).and_raise(StandardError, "unexpected disk error")
          end
        )
      end

      it "raises a ParsingError with a generic message" do
        expect { service.call }.to raise_error(CvParserService::ParsingError, "CV file could not be processed")
      end
    end

    context "when Gemini API returns a non-success response" do
      before do
        allow(CvTextExtractor).to receive(:new).with(document).and_return(
          instance_double(CvTextExtractor, call: "some CV text")
        )

        http_response = instance_double(Net::HTTPServerError, body: "Internal Server Error", code: "500")
        allow(http_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
        allow(Net::HTTP).to receive(:post).and_return(http_response)
      end

      it "raises a ParsingError" do
        expect { service.call }.to raise_error(CvParserService::ParsingError, /Gemini API wrong response/)
      end
    end

    context "when Gemini returns malformed JSON" do
      before do
        allow(CvTextExtractor).to receive(:new).with(document).and_return(
          instance_double(CvTextExtractor, call: "some CV text")
        )

        malformed_body = {
          "candidates" => [{ "content" => { "parts" => [{ "text" => "not valid json {{{" }] } }]
        }.to_json

        http_response = instance_double(Net::HTTPSuccess, body: malformed_body)
        allow(http_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        allow(Net::HTTP).to receive(:post).and_return(http_response)
      end

      it "returns empty_result and logs the error" do
        expect(Rails.logger).to receive(:error).with(/JSON parse error/)
        result = service.call
        expect(result["first_name"]).to be_nil
      end
    end

    context "when Gemini response contains no text" do
      before do
        allow(CvTextExtractor).to receive(:new).with(document).and_return(
          instance_double(CvTextExtractor, call: "some CV text")
        )

        empty_body = { "candidates" => [{ "content" => { "parts" => [] } }] }.to_json

        http_response = instance_double(Net::HTTPSuccess, body: empty_body)
        allow(http_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        allow(Net::HTTP).to receive(:post).and_return(http_response)
      end

      it "raises a ParsingError" do
        expect { service.call }.to raise_error(CvParserService::ParsingError, /does not contain text/)
      end
    end

    context "when Gemini wraps its response in markdown code fences" do
      before do
        allow(CvTextExtractor).to receive(:new).with(document).and_return(
          instance_double(CvTextExtractor, call: "some CV text")
        )

        fenced_json = "```json\n#{{ first_name: 'Fenced', last_name: nil, email: nil, phone: nil, city: nil, country: nil, languages: [], desired_job_function_guess: nil, big_number: nil, big_status_guess: nil, years_of_combined_experience: nil, educations: [], work_experiences: [], skills: [], professional_summary: nil }.to_json}\n```"

        body = { "candidates" => [{ "content" => { "parts" => [{ "text" => fenced_json }] } }] }.to_json

        http_response = instance_double(Net::HTTPSuccess, body: body)
        allow(http_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        allow(Net::HTTP).to receive(:post).and_return(http_response)
      end

      it "strips the code fences and parses correctly" do
        result = service.call
        expect(result["first_name"]).to eq("Fenced")
      end
    end
  end

  describe "PLATFORM_JOB_CATEGORIES" do
    it "matches CandidateProfile::JOB_FUNCTIONS values" do
      expect(CvParserService::PLATFORM_JOB_CATEGORIES).to eq(CandidateProfile::JOB_FUNCTIONS.values)
    end
  end
end
