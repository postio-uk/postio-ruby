# frozen_string_literal: true

require "spec_helper"

# Live tests against api.postio.co.uk (or stage). Skipped automatically
# when no key is in env. Tagged :live so the offline run can exclude
# them and the CI live job opts in.
RSpec.describe "live API", :live do
  before(:all) do
    WebMock.allow_net_connect!
  end

  after(:all) do
    WebMock.disable_net_connect!(allow_localhost: false)
  end

  let(:client) do
    if (key = ENV["POSTIO_API_KEY_STAGE"])
      Postio::Client.new(api_key: key, base_url: "https://stage-api.postio.co.uk/v1")
    elsif (key = ENV["POSTIO_API_KEY_PROD"])
      Postio::Client.new(api_key: key)
    elsif (key = ENV["POSTIO_API_KEY"])
      Postio::Client.new(api_key: key)
    else
      skip "no POSTIO_API_KEY* env var set"
    end
  end

  it "connects" do
    r = client.connect
    expect(r.success).to be true
    expect(r.meta.request_id).not_to be_empty
  end

  it "searches addresses" do
    r = client.address.search("downing street", max_results: 3)
    expect(r.success).to be true
    expect(r.results).not_to be_empty
    expect(r.results[0].udprn).to be > 0
  end

  it "validates emails" do
    r = client.email.validate("admin@postio.co.uk")
    expect(r.success).to be true
    expect(r.results.length).to eq 1
    expect(r.results[0].is_valid_syntax).to be true
  end

  it "validates phone numbers" do
    r = client.phone.validate("+442079460000")
    expect(r.success).to be true
    expect(r.results.length).to eq 1
    expect(r.results[0].is_valid).to be true
  end
end
