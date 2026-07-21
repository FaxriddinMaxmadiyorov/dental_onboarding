class ParseCandidateCvJob < ApplicationJob
  queue_as :default

  def perform(document_id)
    document = CandidateDocument.find(document_id)
    document.update!(parsing_status: "processing")

    parsed = CvParserService.new(document).call
    document.update!(
      parsed_data: parsed,
      parsing_status: "completed",
      parsed_at: Time.current
    )

    ProfilePrefillService.new(document.candidate_profile, parsed).call
  rescue => e
    document.update!(parsing_status: "failed")
    Rails.logger.error("CV parsing failed for document #{document_id}: #{e.message}")
  end
end
