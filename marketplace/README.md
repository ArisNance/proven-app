# Proven Marketplace

Multi-vendor marketplace scaffold built for Rails 7.1 + Spree Commerce with:

- Maker/Buyer/Admin roles
- Stripe Connect Express + listing fee billing
- ShipStation shipping integration
- Shopify two-way sync foundation
- OpenAI-powered moderation and recommendation service contracts
- Sidekiq background jobs
- DaisyUI + Tailwind themed UI

## Security Notice

The previously shared API keys must be considered exposed and rotated immediately. This project uses env vars only.

## Local Setup (after installing Ruby 3.2+)

1. Install dependencies:

```bash
bundle install
npm install
```

2. Prepare DB:

```bash
bin/rails db:create db:migrate
```

3. Start app + worker:

```bash
bin/dev
bundle exec sidekiq
```

## Test API Flow Checklist

Use test keys only while validating integrations:

1. Stripe checkout test:
   - Set `STRIPE_SECRET_KEY` and `STRIPE_WEBHOOK_SECRET`.
   - Open any product page and run **Buy it now** to create a Stripe Checkout Session.
   - Confirm payment using Stripe test card `4242 4242 4242 4242`.
   - Forward webhooks locally (example: `stripe listen --forward-to localhost:3000/webhooks/stripe`).

2. Shopify OAuth + sync test:
   - Set `SHOPIFY_API_KEY`, `SHOPIFY_API_SECRET`, `SHOPIFY_SCOPES`, `APP_HOST`.
   - Start OAuth at `/shopify/oauth/start?shop=<your-store>.myshopify.com` while signed in.
   - Trigger product sync via `POST /shopify/sync/run`.

3. ShipStation webhook + tracking test:
   - Set `SHIPSTATION_API_KEY`, `SHIPSTATION_API_SECRET`, `SHIPSTATION_WEBHOOK_SECRET`.
   - Send test webhook payloads to `POST /webhooks/shipstation`.
   - Background job fetches resource payload and attempts shipment tracking updates.

## Architecture Highlights

- `Moderation::Gate.evaluate(listing_id)`
- `Recommendations::Engine.for_buyer(buyer_id)`
- `Billing::ListingFees.sync!(shop_id)`

See `docs/IMPLEMENTATION_NOTES.md` for phase mapping and `docs/RAILS8_UPGRADE_PATH.md` for upgrade planning.
