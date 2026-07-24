FactoryBot.define do
  factory :candidate_document do
    candidate_profile
    document_type { "cv" }
    parsing_status { "pending" }

    after(:build) do |document|
      document.file.attach(
        io: StringIO.new("fake pdf content"),
        filename: "test_cv.pdf",
        content_type: "application/pdf"
      )
    end
  end
end
