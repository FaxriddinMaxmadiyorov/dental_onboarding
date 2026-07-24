class Skill < ApplicationRecord
  has_many :candidate_skills, dependent: :destroy
  scope :for_function, ->(function_group) { where(function_group: function_group) }
end
