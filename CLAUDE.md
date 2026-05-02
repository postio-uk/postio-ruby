# postio-ruby — development notes

Ruby SDK for the [Postio API](https://postio.co.uk). Mirrors `@postio/core`
(the JS family's runtime client) with idiomatic Ruby ergonomics. Lives
in its own repo because Ruby's gem toolchain doesn't co-exist with the
JS-family pnpm workspace.

Read [`README.md`](./README.md) for the customer-facing surface; this
file is the operational guide for contributors and code agents.

## Stack

- **Ruby 3.2+** required (uses `Data.define` everywhere in `models.rb`).
- **HTTP**: stdlib `net/http`. Zero runtime gems.
- **Tests**: RSpec 3 + WebMock. Live tests in `spec/live_spec.rb`,
  excluded from default rspec via `.rspec` config; CI opts in.

## Layout

```
postio-ruby/
├── postio.gemspec
├── Gemfile
├── lib/
│   ├── postio.rb
│   └── postio/
│       ├── version.rb
│       ├── errors.rb       Postio::Error + 9 typed subclasses
│       ├── models.rb       all Data.define value classes + envelopes
│       └── client.rb       Postio::Client + AddressResource/EmailResource/PhoneResource
├── spec/
│   ├── spec_helper.rb
│   ├── client_spec.rb      offline (WebMock-mocked)
│   └── live_spec.rb         live (skipped by default; CI opts in)
└── .github/workflows/
    ├── ci.yml              rspec matrix on Ruby 3.2/3.3
    └── release.yml         tag-driven; rubygems/release-gem + OIDC TP
```

## Common commands

```bash
bundle install
bundle exec rspec                          # offline only (live excluded by .rspec)
bundle exec rspec spec/live_spec.rb         # live (needs key in env)
gem build postio.gemspec                   # sanity build
```

Local dev picks up `~/PROJECTS/ONNO/POSTIO/.env` via `set -a && source
../.env && set +a` before invoking rspec on `spec/live_spec.rb`.

## Branch + deploy model

- `stage` — working branch.
- `master` — push triggers the live-test job. Tag `vX.Y.Z` → release
  workflow → RubyGems publish.
- `release.yml` is **idempotent** (skips if version already on
  rubygems.org). Auth via **Trusted Publishers (OIDC)** — no
  `RUBYGEMS_API_KEY` secret. Configure once at:
  https://rubygems.org/profile/oidc/api_key_roles
  Bind to `(postio-uk/postio-ruby, release.yml, environment: rubygems)`.

## Spec drift

`PhoneResult` carries the same drift handling as the other SDKs: every
nullable field defaults to `nil` (handled by hash lookup returning
`nil` for missing keys), and `is_reachable` accepts either bool or
string. Reapply if model is regenerated.

## Secrets the CI needs

| Secret | Used by |
|---|---|
| `POSTIO_API_KEY_STAGE` | live-test job in `ci.yml` |

No `RUBYGEMS_API_KEY` — Trusted Publishers handle auth.

