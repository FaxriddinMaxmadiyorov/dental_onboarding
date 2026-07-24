module AuthenticationHelpers
  def sign_in_as(user)
    post login_path, params: { email_address: user.email_address, password: user.password }
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
end
