require "rails_helper"

RSpec.describe Language, type: :model do
  describe "associations" do
    it "has many candidate_languages" do
      language = create(:language)
      candidate_language = create(:candidate_language, language: language)
      expect(language.candidate_languages).to include(candidate_language)
    end
  end
end
