# Changelog

All notable changes to `postio` are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versioning
follows [SemVer](https://semver.org/).

## [Unreleased]

## [0.1.0] — 2026-05-02

Initial release. First Postio Ruby SDK on RubyGems.

### Added

- `Postio::Client` (synchronous; Ruby's async story is fragmented and
  SDK customers want blocking calls).
- Address: `client.address.search/postcode/udprn`.
- Email: `client.email.validate`.
- Phone: `client.phone.validate`.
- Health probe: `client.connect`.
- Immutable `Data` value classes (Ruby 3.2+) for every response.
- Typed error hierarchy: `Postio::Error` base + 9 subclasses
  (`InvalidKeyError`, `OutOfCreditError`, `ForbiddenError`,
  `NotFoundError`, `ValidationError`, `RateLimitError`, `ServerError`,
  `TimeoutError`, `ConnectionError`). Each carries `status`,
  `error_code`, `details`, `request_id`, `envelope`.
- Default retry policy (2 retries, exp backoff + full jitter on
  408/409/429/5xx + network/timeout). Mirrors `@postio/node`.
- Stdlib `net/http` only — no runtime dependencies.
- `POSTIO_API_KEY` env var fallback when `api_key:` is not passed.

### Notes

- `PhoneResult#is_reachable` is plain `Object` (untyped) because the
  live API returns booleans there even though the spec says
  string-only. Aligned once postio-api ships a spec/runtime fix.

[Unreleased]: https://github.com/postio-uk/postio-ruby/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/postio-uk/postio-ruby/releases/tag/v0.1.0
