class User < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :destroy
  validates :email_address, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }
end
