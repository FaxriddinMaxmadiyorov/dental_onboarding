class ParseCandidateCvJob < ApplicationJob
  queue_as :default

  def perform(document_id)
    document = CandidateDocument.find(document_id)
    document.processing!
    broadcast_status(document)

    parsed = Timeout.timeout(20) { CvParserService.new(document).call }

    document.update!(
      parsed_data: parsed,
      parsed_at: Time.current
    )
    document.completed!

    ProfilePrefillService.new(document.candidate_profile, parsed).call

    broadcast_status(document)
  rescue Timeout::Error => e
    Rails.logger.error("CV parsing timed out for document #{document_id}: #{e.message}")
    document&.update!(parsing_status: "failed", parsing_error: "Processing took too long")
    broadcast_status(document)
  rescue => e
    Rails.logger.error("CV parsing failed for document #{document_id}: #{e.message}")
    document&.update!(parsing_status: "failed", parsing_error: e.message)

    broadcast_status(document)
  end

  private

  def broadcast_status(document)
    Turbo::StreamsChannel.broadcast_replace_to(
      "cv_status_#{document.candidate_profile_id}",
      target: "cv_status",
      partial: "candidate_onboardings/cv_status",
      locals: { document: document }
    )
  end
end
