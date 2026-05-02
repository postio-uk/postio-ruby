# frozen_string_literal: true

require "webmock/rspec"
require "postio"

# Block all external network unless tests opt-in via webmock.
WebMock.disable_net_connect!(allow_localhost: false)

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
  config.filter_run_when_matching :focus
end
