# Implementation Notes

## Phase Coverage in this scaffold

1. Core platform setup:
   - Rails 7.1-compatible project skeleton
   - Spree, Sidekiq, Tailwind, DaisyUI dependencies configured
   - Brand tokens and base layout added
2. Auth + marketplace logic:
   - Devise + Google OAuth controller and config
   - Maker/Buyer/Admin roles and core models
3. Product/admin flows:
   - Product wizard React island
   - Admin approvals dashboard + moderation table placeholders
4. AI/ML engine:
   - `Moderation::Gate` contract and job pipeline
   - `Recommendations::Engine` + cache model contract
5. Payments/shipping:
   - Stripe Connect service + webhook idempotency model
   - Listing fee sync service contract
   - ShipStation webhook and job wiring
6. Dashboards/messaging:
   - Dashboard screen + messaging models/controllers/channel
7. Integrations/polish:
   - Shopify OAuth/sync endpoints and services
   - Resend mailer baseline

## Next implementation steps

- Install Ruby 3.2+, Rails, PostgreSQL, Redis, and run setup commands.
- Mount and extend Spree storefront/admin resources.
- Replace placeholder service internals with production API calls and retry/backoff behavior.
- Add policy coverage and full end-to-end system specs.
