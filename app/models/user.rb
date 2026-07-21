class User < ApplicationRecord
  has_secure_password
  has_one :candidate_profile, dependent: :destroy

  validates :email, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }

end
