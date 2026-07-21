class Skill < ApplicationRecord
  has_many :candidate_skills
  scope :for_function, ->(function_group) { where(function_group: function_group) }
end
