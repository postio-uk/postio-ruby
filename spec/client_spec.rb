# frozen_string_literal: true

require "spec_helper"

RSpec.describe Postio::Client do
  let(:api_key)  { "pk_test" }
  let(:base_url) { "https://api.postio.co.uk/v1" }
  let(:client)   { described_class.new(api_key: api_key, retries: 0) }

  describe "#address.search" do
    it "returns a typed envelope" do
      stub_request(:get, "#{base_url}/address/search")
        .with(query: { q: "downing", max_results: "5" })
        .to_return(
          status: 200,
          headers: { "Content-Type" => "application/json" },
          body: {
            success: true,
            results: [{ udprn: 12345, suggestion: "10 Downing Street" }],
            meta: {
              countResults: 1,
              requestId: "abc-123",
              performance: { workerMs: 10, lookupMs: 5 }
            }
          }.to_json
        )

      r = client.address.search("downing", max_results: 5)
      expect(r.success).to be true
      expect(r.results.length).to eq 1
      expect(r.results[0].udprn).to eq 12345
      expect(r.meta.request_id).to eq "abc-123"
    end

    it "sends auth + UA headers" do
      stub_request(:get, "#{base_url}/address/search")
        .with(query: { q: "x" }, headers: {
          "X-Api-Key"      => "pk_test",
          "Accept"         => "application/json",
          "User-Agent"     => /\Apostio-ruby\//
        })
        .to_return(status: 200,
                   headers: { "Content-Type" => "application/json" },
                   body: { success: true, results: [], meta: { countResults: 0, requestId: "r", performance: { workerMs: 0, lookupMs: 0 } } }.to_json)

      client.address.search("x")
      # If the stub above was fulfilled, the headers must have matched.
      expect(WebMock).to have_requested(:get, "#{base_url}/address/search").with(query: { q: "x" })
    end
  end

  describe "error mapping" do
    {
      401 => [Postio::InvalidKeyError, "invalid_api_key"],
      402 => [Postio::OutOfCreditError, "out_of_credit"],
      403 => [Postio::ForbiddenError, "forbidden"],
      404 => [Postio::NotFoundError, "not_found"],
      400 => [Postio::ValidationError, "bad_request"],
      500 => [Postio::ServerError, "internal"]
    }.each do |status, (klass, code)|
      it "maps HTTP #{status} → #{klass.name}" do
        stub_request(:get, "#{base_url}/connect")
          .to_return(
            status: status,
            headers: { "Content-Type" => "application/json" },
            body: {
              success: false, error: code, results: [],
              meta: { countResults: 0, requestId: "req-#{status}", performance: { workerMs: 1, lookupMs: 0 } }
            }.to_json
          )

        expect { client.connect }.to raise_error(klass) do |err|
          expect(err.status).to eq status
          expect(err.error_code).to eq code
          expect(err.request_id).to eq "req-#{status}"
        end
      end
    end

    it "surfaces Retry-After on rate limit" do
      stub_request(:get, "#{base_url}/connect")
        .to_return(
          status: 429,
          headers: { "Content-Type" => "application/json", "Retry-After" => "12" },
          body: {
            success: false, error: "rate_limited", results: [],
            meta: { countResults: 0, requestId: "r-429", performance: { workerMs: 1, lookupMs: 0 } }
          }.to_json
        )

      expect { client.connect }.to raise_error(Postio::RateLimitError) do |err|
        expect(err.retry_after).to eq 12.0
      end
    end
  end

  describe "retries" do
    it "retries 5xx then succeeds" do
      stub = stub_request(:get, "#{base_url}/connect")
        .to_return(
          {
            status: 503,
            headers: { "Content-Type" => "application/json" },
            body: { success: false, error: "unavailable", results: [], meta: { countResults: 0, requestId: "r1", performance: { workerMs: 1, lookupMs: 0 } } }.to_json
          },
          {
            status: 200,
            headers: { "Content-Type" => "application/json" },
            body: { success: true, meta: { requestId: "r-ok", performance: { workerMs: 5, lookupMs: 2 } } }.to_json
          }
        )

      retried = described_class.new(api_key: "pk_test", retries: 2)
      r = retried.connect
      expect(r.success).to be true
      expect(r.meta.request_id).to eq "r-ok"
      expect(stub).to have_been_requested.times(2)
    end
  end

  describe "constructor" do
    it "raises when no api key" do
      ENV.delete("POSTIO_API_KEY")
      expect { described_class.new }.to raise_error(ArgumentError, /api_key is required/)
    end
  end
end
