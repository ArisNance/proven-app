# UI/UX Execution Board (Etsy-Inspired, Proven-Branded)

## Design Direction Guardrails

- Goal: Match Etsy-like usability patterns (clean marketplace IA, strong search/discovery, trustworthy listing cards, clear CTAs) while preserving Proven brand (black/white/grays + flat yellow accent).
- Do not copy Etsy visuals 1:1. Recreate interaction patterns and information hierarchy with our own typography, spacing, icon style, and motion.
- Global UX targets:
  - Fast scanability on desktop and mobile.
  - Clear buyer vs maker vs admin pathways.
  - Complete states for loading, empty, error, and success.
  - WCAG-friendly keyboard and contrast behavior.

## Board Legend

- Priority:
  - `P0`: Must-have before production launch.
  - `P1`: Needed for strong polish at launch.
  - `P2`: Post-launch enhancement.
- Status: `TODO`, `IN PROGRESS`, `DONE`.

## Global System Work (applies to all pages)

| ID | Priority | Status | Scope | Execution Steps | Acceptance Criteria |
|---|---|---|---|---|---|
| SYS-01 | P0 | TODO | Design tokens + components | Finalize typography scale, spacing, card styles, button/input variants, badges, alerts, table styles in shared partials/helpers. | All pages use shared UI primitives; no page-specific one-off styles for common elements. |
| SYS-02 | P0 | TODO | Header / nav / footer | Build Etsy-like utility header with search slot + role-aware navigation + consistent footer. | Navigation is consistent across all pages and role paths are obvious. |
| SYS-03 | P0 | TODO | States framework | Create reusable empty/loading/error/success components. | Every critical page has complete non-happy-path states. |
| SYS-04 | P0 | TODO | Responsive polish | Standardize breakpoints and spacing behavior (mobile-first). | No overflow, clipped controls, or unreadable text from 360px to desktop. |
| SYS-05 | P0 | TODO | Accessibility baseline | Keyboard focus, semantic headings, label/aria cleanup, contrast pass. | Basic WCAG checks pass and all primary actions are keyboard-accessible. |
| SYS-06 | P1 | TODO | Motion + delight | Add restrained motion presets (panel reveal, list stagger, button feedback). | Motion feels intentional and never blocks task completion. |

## Page-by-Page Execution Board

| ID | Priority | Status | Page | Etsy-Inspired Layout Goal | Execution Steps | Acceptance Criteria |
|---|---|---|---|---|---|---|
| PAGE-01 | P0 | TODO | `/` Home ([home/index](/Users/valuedcustomer/Desktop/Proven%20App/marketplace/app/views/home/index.html.erb)) | Marketplace landing with search-first hero, featured categories, trust signals, and maker CTA. | Add sticky search header, hero with primary search + category chips, curated sections (featured makers, trending items), trust strip, clear buyer/maker CTAs. | User can understand value + next action in <5 seconds; mobile and desktop both clear. |
| PAGE-02 | P0 | TODO | Global layout ([layouts/application](/Users/valuedcustomer/Desktop/Proven%20App/marketplace/app/views/layouts/application.html.erb)) | Marketplace shell with Etsy-like browse flow. | Add utility nav (categories, favorites, cart placeholder, account), secondary breadcrumbs slot, standardized flash region, footer links. | Shell supports storefront + dashboard contexts without layout jumps. |
| PAGE-03 | P0 | TODO | Maker onboarding `/makers/onboarding` ([makers/onboarding/show](/Users/valuedcustomer/Desktop/Proven%20App/marketplace/app/views/makers/onboarding/show.html.erb)) | Guided multi-step maker setup with confidence cues. | Convert single form to stepper (profile, business basics, payout setup intro), add progress rail, inline validation and save/resume messaging. | Completion rate-friendly flow with clear progress and no ambiguous field labels. |
| PAGE-04 | P0 | TODO | Maker shops list `/makers/shops` ([makers/shops/index](/Users/valuedcustomer/Desktop/Proven%20App/marketplace/app/views/makers/shops/index.html.erb)) | Etsy seller-manager style list with status and quick actions. | Replace plain table with responsive list/table hybrid, add filters (status), sortable columns, quick actions (edit/view/duplicate). | Makers can find and act on a listing in <=2 clicks. |
| PAGE-05 | P0 | TODO | New shop + product upload `/makers/shops/new` ([makers/shops/new](/Users/valuedcustomer/Desktop/Proven%20App/marketplace/app/views/makers/shops/new.html.erb)) | Focused creation workspace with side guidance. | Split into 2-column layout: form + checklist/help panel, make React product wizard modal/drawer style, add completion checklist and draft save. | No dead-end state; makers always know next required step. |
| PAGE-06 | P1 | TODO | Shop detail `/makers/shops/:id` ([makers/shops/show](/Users/valuedcustomer/Desktop/Proven%20App/marketplace/app/views/makers/shops/show.html.erb)) | Seller profile preview with performance + readiness summary. | Add shop hero, readiness checklist, listing metrics cards, moderation/payment status timeline. | Maker can immediately see approval and publishing readiness. |
| PAGE-07 | P0 | TODO | Admin approvals `/admin/approvals` ([admin/approvals/index](/Users/valuedcustomer/Desktop/Proven%20App/marketplace/app/views/admin/approvals/index.html.erb)) | Operations console with queue triage. | Add split-pane queue UX (left list/right details), filters/search, risk badges, bulk actions, action confirmations with rationale fields. | Admin can process reviews quickly with clear risk context. |
| PAGE-08 | P0 | TODO | Conversations list `/conversations` ([conversations/index](/Users/valuedcustomer/Desktop/Proven%20App/marketplace/app/views/conversations/index.html.erb)) | Inbox-first messaging overview. | Add sender avatars, unread badges, latest message preview, timestamp grouping, search/filter by counterpart. | Inbox is scannable and unread items are obvious. |
| PAGE-09 | P0 | TODO | Conversation detail `/conversations/:id` ([conversations/show](/Users/valuedcustomer/Desktop/Proven%20App/marketplace/app/views/conversations/show.html.erb)) | Etsy-like buyer/seller thread with product context. | Add conversation header with participant + linked item summary, better bubble hierarchy, typing/seen placeholders, sticky composer with attachments placeholder. | Messaging feels real-time and context-rich on mobile + desktop. |
| PAGE-10 | P0 | TODO | Dashboard `/dashboard` ([dashboard/index](/Users/valuedcustomer/Desktop/Proven%20App/marketplace/app/views/dashboard/index.html.erb)) | Role-based control center. | Split buyer/maker/admin variants, add KPI cards, priority tasks, recent activity feed, quick actions grid. | Dashboard has role-appropriate signal and next actions. |
| PAGE-11 | P0 | TODO | Auth screens (to create) | Clean, trustworthy sign-in/up and OAuth flow. | Add branded Devise views for sign-in/sign-up/password reset and Google OAuth callouts; include inline errors and support links. | Auth flows are consistent with main brand and have complete error messaging. |
| PAGE-12 | P0 | TODO | Error pages (to create) | Friendly recovery UX (404/422/500). | Build branded error templates with primary recovery actions and support links. | No default Rails error pages in user-facing contexts. |
| PAGE-13 | P1 | TODO | Storefront browse page (to create) | Etsy-style discovery grid with filters/search. | Build product grid, sticky filter rail, sort controls, result count, pagination/infinite-scroll decision. | Buyers can discover products quickly with low cognitive load. |
| PAGE-14 | P1 | TODO | Product detail page (to create) | Trust-focused listing detail with maker profile context. | Add gallery, price/shipping summary, seller trust panel, similar items, clear buy/save actions. | Product detail supports confident purchase decisions. |

## Final UX Readiness Gates (before integration hardening)

- `Gate A`: Every `P0` page has polished primary flow + complete states.
- `Gate B`: Mobile QA pass complete for iPhone-sized and tablet breakpoints.
- `Gate C`: Accessibility checklist passed for keyboard and contrast.
- `Gate D`: Visual consistency pass complete against shared design system.

## Sequencing Recommendation

1. `SYS-01` to `SYS-04` (foundation first)
2. `PAGE-01` and `PAGE-02` (global shell + home)
3. Maker surfaces (`PAGE-03` to `PAGE-06`)
4. Admin + messaging (`PAGE-07` to `PAGE-10`)
5. Missing critical pages (`PAGE-11` and `PAGE-12`)
6. Storefront depth (`PAGE-13` and `PAGE-14`)
7. Run final UX readiness gates, then focus fully on Stripe/Shopify/ShipStation production hardening.
