class User < ApplicationRecord
  has_secure_password

  has_one :candidate_profile, dependent: :destroy
  has_many :sessions, dependent: :destroy

  validates :email_address, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }

  enum :role, {
    candidate: "candidate",
    admin: "admin"
  }
end
