class Education < ApplicationRecord
  belongs_to :candidate_profile
  validates :study, presence: true
  LEVELS = %w[MBO HBO Bachelor Master Doctor Course].freeze
end
