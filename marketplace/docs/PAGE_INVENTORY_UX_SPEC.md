# Proven Marketplace Page Inventory + UX Spec

## Design System Lock

- Typography:
  - Body/UI: `Inter`
  - Headlines/metrics: `Roboto`
- Color tokens:
  - `primary`: `#1F2937`
  - `accent`: `#D4F93D`
  - `surface`: `#F9F9F9`
  - `border`: `#E5E7EB`
  - `text`: `#0F172A`
- Spacing scale: `4, 8, 12, 16, 24, 32, 48`
- Radius scale: `1rem, 1.5rem, 2rem`
- Elevation:
  - Surface: soft shadow (`0 20px 40px -15px rgba(15,23,42,.08)`)
  - Poster/hero: elevated shadow (`0 30px 60px -10px rgba(15,23,42,.12)`)
- Icon style: simple linear icons inside circular/rounded action surfaces
- Controls:
  - Primary action: filled `primary` pill
  - Secondary action: outlined neutral pill
  - Inputs: bordered, full-width, with helper text and inline error copy
- Shared components:
  - `shared/_breadcrumbs`
  - `shared/_page_header`
  - `shared/_quick_actions`
  - `shared/_flash`
  - `shared/_empty_state`
  - `shared/_form_error_summary`

## Role Navigation IA

- Buyer context:
  - Home, Dashboard, Messages
- Maker context:
  - Home, Dashboard, Messages, Maker Onboarding, Shops
- Admin context:
  - Home, Dashboard, Messages, Approvals
- Global shell:
  - Sticky top nav
  - Role badge
  - Search slot
  - Quick action bar below header
  - Breadcrumb + page header on interior pages

## Route Inventory

| Route/View | Purpose | Primary CTA | Success State | Empty State | Loading State | Error State |
|---|---|---|---|---|---|---|
| `/` Home | Guest: handmade retailer landing. Signed-in: operational launchpad. | `Shop handmade` (guest) / role action (signed-in) | Guest hero + featured products + maker story, or signed-in KPI panel | N/A | Page transition animation | Global flash on load issues |
| `/products` | Browse catalog with category/search filters | `Apply` / product `View` | Product grid with reusable cards | Shared empty state with clear-filters CTA | Filter submit/loading state | Flash + empty fallback |
| `/products/:id` | Product detail with maker trust context | `Add to bag` (placeholder) | Product story + pricing + maker context | N/A | N/A | Redirect with flash if missing |
| `/users/sign_in` | Authenticate user | `Sign in` | User redirected to workspace | N/A | Submit button becomes busy | Inline + summary validation |
| `/users/sign_up` | Register account | `Create account` | Account created and signed in | N/A | Submit button becomes busy | Inline + summary validation |
| `/users/password/new` | Start reset flow | `Send reset instructions` | Notice flash confirms email flow | N/A | Submit button becomes busy | Inline + summary validation |
| `/users/password/edit` | Complete password reset | `Update password` | Password changed and session path resumed | N/A | Submit button becomes busy | Inline + summary validation |
| `/makers/onboarding` | Build maker profile + payout readiness | `Save and continue` | Profile saved and move to shop creation | Checklist guidance if no Stripe link yet | Submit button busy; staged progress panel | Error summary + per-field errors |
| `/makers/shops` | Manage maker shops | `Create shop` | Table shows approval/billing status | Empty state with first shop CTA | Filter state change navigation | Flash warning if billing unavailable |
| `/makers/shops/new` | Create shop + submit for approval | `Submit for approval` | Redirect to shop detail with status | N/A | Submit button busy + product wizard progress | Validation summary and inline errors |
| `/makers/shops/:id` | Single-shop readiness and billing state | `New shop` | Approval/billing/payout cards populated | Fallback copy where data missing | N/A | Flash + fallback statuses |
| `/admin/approvals` | Queue triage for shop/product/flags | `Approve` / `Reject` | Action flash and queue count updates | Empty queue state card | Immediate button feedback on submit | Access control alert for non-admin |
| `/conversations` | Inbox overview | `Open` thread | List with preview + timestamps | Empty state points to dashboard | N/A | Flash on fetch issues |
| `/conversations/:id` | Thread detail and messaging | `Send message` | Message appears in thread + flash | Empty state invites first message | Composer submit busy state | Validation alert on message body |
| `/dashboard` | Role-based operational command center | Role quick actions | Metrics + priorities + recent activity | First-time guidance for new role users | N/A | Flash for auth/policy issues |
| `/404` | Not found recovery | `Go home` | User redirected from CTA | N/A | N/A | Branded 404 copy |
| `/422` | Invalid request recovery | `Go home` | User resumes workflow | N/A | N/A | Branded 422 copy |
| `/500` | Unexpected failure recovery | `Return home` | User exits failed path | N/A | N/A | Branded 500 copy |

## State Completeness Baseline

- Success:
  - Flash banners on create/update/send flows
- Empty:
  - Shared empty-state component on dashboard activity, shops, conversations, approvals
- Loading:
  - Form submit busy state controller (`form-state`) disables submit and announces progress
- Error:
  - Shared form-level summary and inline field-level messaging

## Accessibility Baseline

- Semantic landmarks: `header`, `main`, `footer`, labeled navigation
- Keyboard:
  - Visible focus rings on interactive controls
  - Skip link to `main`
- Forms:
  - Required indicators, helper text, inline errors, summary alerts
- Screen readers:
  - Flash regions use live regions
  - Error summaries use `role="alert"`
