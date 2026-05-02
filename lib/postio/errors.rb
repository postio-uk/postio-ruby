# frozen_string_literal: true

module Postio
  # Base class for every Postio API failure.
  #
  # All instances carry: status (HTTP code, 0 for transport errors),
  # error_code (the API's error string), details, request_id, and the
  # raw envelope hash for any field this class doesn't expose.
  class Error < StandardError
    attr_reader :status, :error_code, :details, :request_id, :envelope, :cause_error

    def initialize(message, status: 0, error_code: nil, details: nil, request_id: nil, envelope: nil, cause: nil)
      super(message)
      @status      = status
      @error_code  = error_code
      @details     = details
      @request_id  = request_id
      @envelope    = envelope
      @cause_error = cause
    end
  end

  class ValidationError   < Error; end  # 400 / 422
  class InvalidKeyError   < Error; end  # 401
  class OutOfCreditError  < Error; end  # 402
  class ForbiddenError    < Error; end  # 403
  class NotFoundError     < Error; end  # 404
  class ServerError       < Error; end  # 5xx
  class TimeoutError      < Error; end  # local request timeout
  class ConnectionError   < Error; end  # transport-level error

  # 429 — rate limited. {#retry_after} is the API's suggested wait in seconds.
  class RateLimitError < Error
    attr_reader :retry_after

    def initialize(message, retry_after: nil, **kwargs)
      super(message, **kwargs)
      @retry_after = retry_after
    end
  end

  # Map an HTTP status to the typed error class.
  STATUS_ERRORS = {
    400 => ValidationError,
    401 => InvalidKeyError,
    402 => OutOfCreditError,
    403 => ForbiddenError,
    404 => NotFoundError,
    422 => ValidationError,
    429 => RateLimitError
  }.freeze

  def self.error_class_for(status)
    return STATUS_ERRORS[status] if STATUS_ERRORS.key?(status)
    return ServerError if status >= 500

    Error
  end
end
