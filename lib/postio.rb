# frozen_string_literal: true

require_relative "postio/version"
require_relative "postio/errors"
require_relative "postio/models"
require_relative "postio/client"

# Top-level Postio module. Use Postio::Client to construct the API client.
#
#   client = Postio::Client.new(api_key: "pk_live_...")
#   client.address.search("downing street")
module Postio
end
