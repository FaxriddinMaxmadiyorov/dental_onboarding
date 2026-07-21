class CandidateLanguage < ApplicationRecord
  belongs_to :candidate_profile
  belongs_to :language
end
