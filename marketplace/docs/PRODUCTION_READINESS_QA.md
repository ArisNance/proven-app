# Production Readiness QA Matrix

## Frontend Quality + Performance Gates

- Lighthouse targets (mobile baseline):
  - Performance >= 80
  - Accessibility >= 90
  - Best Practices >= 90
  - SEO >= 85
- Prevent layout shift:
  - Keep stable heading/container structure across pages
  - Avoid late-injected large media in first viewport
- Bundle hygiene:
  - Build JS/CSS before release (`npm run build && npm run build:css`)
  - Keep React island scoped to product wizard only

## Manual QA Matrix

| Area | Buyer | Maker | Admin |
|---|---|---|---|
| Navigation clarity | Home/dashboard/messages reachable | Onboarding + shops visible | Approvals visible and protected |
| Forms and validation | Auth + messages validate cleanly | Onboarding + shop forms validate cleanly | Approval actions require intent |
| Empty states | Inbox/dashboard guidance present | Shops/dashboard first-time guidance | Queue empty states visible |
| Error states | Auth/form errors announced | Billing/setup failures show non-blocking flash | Unauthorized users blocked with alert |
| Responsive checks | 360px, 768px, 1280px no overflow | Same | Same |

## Browser Coverage

- Chrome (latest)
- Safari (latest)
- Firefox (latest)

## Release Checklist

- [ ] `bundle exec rspec` passes
- [ ] `npm run build` and `npm run build:css` pass
- [ ] Stripe keys present in environment
- [ ] Webhook secrets configured (`STRIPE_WEBHOOK_SECRET`)
- [ ] `APP_HOST` points to deployed domain
- [ ] Admin role verified in production data
- [ ] Error pages `/404`, `/422`, `/500` render with branded layout

## Deploy Notes

- Primary deploy target: Render (`render.yaml` present)
- Pre-deploy:
  - Run DB migrations
  - Ensure Sidekiq worker process configured
- Post-deploy smoke:
  - Sign in/out
  - Maker onboarding save
  - Shop create + approval action
  - Conversation send
  - Stripe webhook endpoint returns 200 for valid signature

