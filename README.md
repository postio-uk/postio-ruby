# Postio Ruby SDK

[![Gem Version](https://img.shields.io/gem/v/postio.svg)](https://rubygems.org/gems/postio)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.1-red)](https://rubygems.org/gems/postio)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Ruby SDK for [Postio](https://postio.co.uk) — the UK validation API for
addresses, emails and phone numbers. Stdlib `net/http` only, zero runtime
dependencies. Backed by Royal Mail PAF and Ordnance Survey.

> **First time?** [Sign up free](https://postio.co.uk) — first 100 lookups on us, no card needed.

## Install

```bash
gem install postio
```

Or in your `Gemfile`:

```ruby
gem "postio", "~> 0.1"
```

Requires Ruby 3.1+.

## 30-second example

```ruby
require "postio"

client = Postio::Client.new(api_key: "pk_...")  # or set POSTIO_API_KEY

result = client.address.search("downing street")
result.results.each do |hit|
  puts "#{hit.udprn}: #{hit.suggestion}"
end

puts "request id: #{result.meta.request_id}"
```

## API

| Method | Returns |
|---|---|
| `client.address.search(q, max_results:)` | `AddressSearchEnvelope` |
| `client.address.postcode(postcode, max_results:)` | `AddressPostcodeEnvelope` |
| `client.address.udprn(udprn)` | `AddressUdprnEnvelope` |
| `client.email.validate(address)` | `EmailEnvelope` |
| `client.phone.validate(number)` | `PhoneEnvelope` |
| `client.connect` | `ConnectSuccess` |

All response objects are immutable `Data` value classes (Ruby 3.2+).
Field names are snake_case in Ruby; the API uses camelCase JSON.

## Errors

Every non-2xx response raises a typed error. `Postio::Error` is the base.

```ruby
begin
  client.address.postcode("not-a-postcode")
rescue Postio::ValidationError => e
  puts "#{e.status} #{e.error_code}: #{e.message} (request_id: #{e.request_id})"
rescue Postio::RateLimitError => e
  puts "rate limited; retry in #{e.retry_after} seconds"
end
```

| Class | HTTP |
|---|---|
| `Postio::ValidationError` | 400 / 422 |
| `Postio::InvalidKeyError` | 401 |
| `Postio::OutOfCreditError` | 402 |
| `Postio::ForbiddenError` | 403 |
| `Postio::NotFoundError` | 404 |
| `Postio::RateLimitError` | 429 (`#retry_after`) |
| `Postio::ServerError` | 5xx |
| `Postio::TimeoutError` | local request timeout |
| `Postio::ConnectionError` | transport error |

Every error carries `status`, `error_code`, `details`, `request_id`, and
the raw `envelope`.

## Configuration

```ruby
client = Postio::Client.new(
  api_key:  "pk_...",
  base_url: "https://api.postio.co.uk/v1",  # default
  timeout:  10,                              # seconds
  retries:  2,                               # 0 to disable
  headers:  { "x-tracking-id" => "..." }
)
```

Default retry policy: 2 retries on 408/409/429/5xx + network/timeout,
exponential backoff with full jitter (0.5s → 8s cap).

## Frameworks

The SDK is framework-agnostic. Cache one `Postio::Client` per process —
it's safe for concurrent use under MRI / YJIT / Truffle.

**Rails** — initialiser:

```ruby
# config/initializers/postio.rb
POSTIO = Postio::Client.new(api_key: Rails.application.credentials.postio_api_key)
```

## Links

- [Docs](https://postio.co.uk/docs)
- [API reference (OpenAPI)](https://postio.co.uk/openapi.json)
- [Changelog](./CHANGELOG.md)
- [Issues](https://github.com/postio-uk/postio-ruby/issues)

## License

MIT — see [LICENSE](./LICENSE).

> *Postio is a trading name of Onno Group Limited, registered in
> England & Wales (company no. 08622799). Registered office:
> Suite 22 Trym Lodge, 1 Henbury Road, Westbury-On-Trym, Bristol BS9 3HQ.*
