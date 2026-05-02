# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

require_relative "version"
require_relative "errors"
require_relative "models"

module Postio
  # Postio::Client is the synchronous Postio API client.
  #
  # Example:
  #
  #   client = Postio::Client.new(api_key: "pk_live_...")
  #   r = client.address.search("downing street")
  #   r.results.each { |hit| puts "#{hit.udprn}: #{hit.suggestion}" }
  #
  # The API key may also come from the POSTIO_API_KEY environment
  # variable.
  class Client
    DEFAULT_BASE_URL = "https://api.postio.co.uk/v1"
    DEFAULT_TIMEOUT  = 10
    RETRYABLE_STATUSES = [408, 409, 429, 500, 502, 503, 504].freeze

    attr_reader :address, :email, :phone

    def initialize(api_key: nil, base_url: DEFAULT_BASE_URL, timeout: DEFAULT_TIMEOUT,
                   retries: 2, headers: {})
      @api_key = api_key || ENV["POSTIO_API_KEY"]
      raise ArgumentError, "Postio: api_key is required (pass api_key: ... or set POSTIO_API_KEY)" if @api_key.nil? || @api_key.empty?

      @base_url       = base_url.chomp("/")
      @timeout        = timeout
      @retries        = retries
      @extra_headers  = headers

      @address = AddressResource.new(self)
      @email   = EmailResource.new(self)
      @phone   = PhoneResource.new(self)
    end

    # Health probe — confirms the API is reachable and the key is valid.
    def connect
      Models::ConnectSuccess.from_hash(request("/connect"))
    end

    # @api private — used by resource classes.
    def request(path, query: {})
      uri = URI(@base_url + path)
      params = query.compact.transform_values(&:to_s)
      uri.query = URI.encode_www_form(params) unless params.empty?

      max_attempts = @retries + 1
      last_error   = nil

      max_attempts.times do |attempt|
        begin
          response = perform_http(uri)
        rescue Net::OpenTimeout, Net::ReadTimeout => e
          last_error = TimeoutError.new("Request timed out.", error_code: "request_timeout", cause: e)
          raise last_error if attempt == max_attempts - 1

          sleep(backoff(attempt))
          next
        rescue StandardError => e
          last_error = ConnectionError.new("Network error: #{e.message}", error_code: "network_error", cause: e)
          raise last_error if attempt == max_attempts - 1

          sleep(backoff(attempt))
          next
        end

        body = parse_body(response)

        if response.is_a?(Net::HTTPSuccess)
          return body
        end

        # Non-2xx — retryable status?
        if RETRYABLE_STATUSES.include?(response.code.to_i) && attempt < max_attempts - 1
          last_error = build_error(response, body)
          sleep(backoff(attempt))
          next
        end

        raise build_error(response, body)
      end

      # Unreachable — loop above either returns or raises.
      raise(last_error || Error.new("Postio: retry loop exhausted unexpectedly."))
    end

    private

    def perform_http(uri)
      req = Net::HTTP::Get.new(uri.request_uri)
      req["x-api-key"]        = @api_key
      req["Accept"]           = "application/json"
      req["User-Agent"]       = "postio-ruby/#{VERSION}"
      req["x-postio-client"]  = "postio-ruby/#{VERSION}"
      @extra_headers.each { |k, v| req[k] = v }

      Net::HTTP.start(uri.hostname, uri.port,
                      use_ssl: uri.scheme == "https",
                      open_timeout: @timeout,
                      read_timeout: @timeout) do |http|
        http.request(req)
      end
    end

    def parse_body(response)
      content_type = (response["content-type"] || "").to_s
      unless content_type.include?("application/json")
        raise Error.new(
          "Unexpected response content-type: #{content_type.inspect}",
          status: response.code.to_i,
          error_code: "unexpected_content_type",
          details: response.body[0, 500]
        )
      end

      JSON.parse(response.body)
    rescue JSON::ParserError => e
      raise Error.new("Failed to parse response body as JSON.",
                      status: response.code.to_i,
                      error_code: "parse_error",
                      cause: e)
    end

    def build_error(response, envelope)
      status     = response.code.to_i
      error      = envelope.is_a?(Hash) ? envelope["error"] : nil
      details    = envelope.is_a?(Hash) ? envelope["details"] : nil
      request_id = envelope.dig("meta", "requestId") if envelope.is_a?(Hash)
      message    = (error || "HTTP #{status}").to_s

      klass = Postio.error_class_for(status)
      kwargs = {
        status:     status,
        error_code: error,
        details:    details,
        request_id: request_id,
        envelope:   envelope.is_a?(Hash) ? envelope : nil
      }

      if klass == RateLimitError
        retry_after_header = response["retry-after"]
        retry_after = retry_after_header && retry_after_header.match?(/\A\d+(\.\d+)?\z/) ? retry_after_header.to_f : nil
        return RateLimitError.new(message, retry_after: retry_after, **kwargs)
      end

      klass.new(message, **kwargs)
    end

    def backoff(attempt)
      base = 0.5
      cap  = 8.0
      exp  = [cap, base * (2**attempt)].min
      rand * exp
    end
  end

  # Resource: /address/*
  class AddressResource
    def initialize(client) = (@client = client)

    def search(q, max_results: nil)
      Models::AddressSearchEnvelope.from_hash(
        @client.request("/address/search", query: { "q" => q, "max_results" => max_results })
      )
    end

    def postcode(postcode, max_results: nil)
      Models::AddressPostcodeEnvelope.from_hash(
        @client.request("/address/postcode/#{URI.encode_www_form_component(postcode)}",
                        query: { "max_results" => max_results })
      )
    end

    def udprn(udprn)
      Models::AddressUdprnEnvelope.from_hash(
        @client.request("/address/udprn/#{URI.encode_www_form_component(udprn.to_s)}")
      )
    end
  end

  # Resource: /email/*
  class EmailResource
    def initialize(client) = (@client = client)

    def validate(address)
      Models::EmailEnvelope.from_hash(
        @client.request("/email/#{URI.encode_www_form_component(address)}")
      )
    end
  end

  # Resource: /phone/*
  class PhoneResource
    def initialize(client) = (@client = client)

    def validate(number)
      Models::PhoneEnvelope.from_hash(
        @client.request("/phone/#{URI.encode_www_form_component(number)}")
      )
    end
  end
end
