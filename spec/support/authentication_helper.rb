module AuthenticationHelper
  def sign_in_as(user)
    host! "example.com"
    post session_path, params: { email_address: user.email_address, password: "password123" }
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelper, type: :request
end
