module CandidateOnboardingsHelper
  def field_status_label(profile, field_name, required: false)
    if profile.field_from_cv?(field_name)
      content_tag(:span, "Extracted from CV; please check",
        class: "text-xs font-normal text-amber-600")
    elsif required && profile.public_send(field_name).blank?
      content_tag(:span, "Missing",
        class: "text-xs font-normal text-red-500")
    end
  end
end
