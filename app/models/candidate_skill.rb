class CandidateSkill < ApplicationRecord
  belongs_to :candidate_profile
  belongs_to :skill, optional: true # optional if free_text_suggestion used
end
