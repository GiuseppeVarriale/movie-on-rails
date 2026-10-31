require "rails_helper"

RSpec.describe "Sidekiq web UI", type: :request do
  around do |example|
    original = ENV.to_h.slice("SIDEKIQ_USERNAME", "SIDEKIQ_PASSWORD")
    ENV["SIDEKIQ_USERNAME"] = username
    ENV["SIDEKIQ_PASSWORD"] = password
    example.run
  ensure
    ENV["SIDEKIQ_USERNAME"] = original["SIDEKIQ_USERNAME"]
    ENV["SIDEKIQ_PASSWORD"] = original["SIDEKIQ_PASSWORD"]
  end

  let(:username) { "admin" }
  let(:password) { "secret" }

  def basic_auth(user, pass)
    { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(user, pass) }
  end

  it "asks for credentials" do
    get "/sidekiq"

    expect(response).to have_http_status(:unauthorized)
  end

  it "rejects wrong credentials" do
    get "/sidekiq", headers: basic_auth("admin", "wrong")

    expect(response).to have_http_status(:unauthorized)
  end

  it "opens the dashboard with the right credentials" do
    get "/sidekiq", headers: basic_auth("admin", "secret")

    expect(response).to have_http_status(:ok)
  end

  context "without configured credentials" do
    let(:username) { "" }
    let(:password) { "" }

    it "denies everyone" do
      get "/sidekiq", headers: basic_auth("", "")

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
