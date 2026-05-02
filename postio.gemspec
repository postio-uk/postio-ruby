# frozen_string_literal: true

require_relative "lib/postio/version"

Gem::Specification.new do |spec|
  spec.name        = "postio"
  spec.version     = Postio::VERSION
  spec.authors     = ["Postio"]
  spec.email       = ["admin@postio.co.uk"]

  spec.summary     = "Ruby SDK for the Postio API — UK address, email, and phone validation."
  spec.description = "Ruby client for the Postio API. UK address, email, and phone validation backed by Royal Mail PAF and Ordnance Survey. Stdlib net/http, no external runtime dependencies."
  spec.homepage    = "https://postio.co.uk"
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata = {
    "homepage_uri"      => "https://postio.co.uk",
    "documentation_uri" => "https://postio.co.uk/docs",
    "source_code_uri"   => "https://github.com/postio-uk/postio-ruby",
    "bug_tracker_uri"   => "https://github.com/postio-uk/postio-ruby/issues",
    "changelog_uri"     => "https://github.com/postio-uk/postio-ruby/blob/master/CHANGELOG.md",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir["lib/**/*.rb", "README.md", "LICENSE", "CHANGELOG.md", "postio.gemspec"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "webmock", "~> 3.23"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.65"
end
