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

## Architecture Highlights

- `Moderation::Gate.evaluate(listing_id)`
- `Recommendations::Engine.for_buyer(buyer_id)`
- `Billing::ListingFees.sync!(shop_id)`

See `docs/IMPLEMENTATION_NOTES.md` for phase mapping and `docs/RAILS8_UPGRADE_PATH.md` for upgrade planning.
