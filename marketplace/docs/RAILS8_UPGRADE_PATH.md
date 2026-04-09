# Rails 8 Upgrade Path

## Baseline

- Runtime target today: Rails 7.1.x on Ruby 3.2+
- Upgrade trigger: all core marketplace and integration tests green in CI

## Checklist

1. Update gems to Rails 8-compatible versions (Rails, Devise, Spree extensions, Sidekiq adapters).
2. Run dual CI matrix for Rails 7.1 and Rails 8 preview branch.
3. Fix deprecations under `RAILS_ENV=test` and production boot logs.
4. Re-run webhook contract tests for Stripe/ShipStation/Shopify.
5. Validate Turbo/Stimulus + React island asset pipeline under Rails 8 defaults.
6. Cut release branch and execute blue/green deploy on Render.
