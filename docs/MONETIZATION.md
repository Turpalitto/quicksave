# Monetization

QuickSave monetization is **privacy-respecting** and **creator-safe**.

## Current state (v1.2.3)

- Google Play subscription billing (`in_app_purchase`) with restore
- Local license keys + demo keys for review/self-hosted
- Optional backend Play receipt verification stub
- No analytics trackers

## Planned Pro features

- Watchlist / scheduler
- Advanced export (ZIP with metadata, JSON, CSV)
- Smart folders & filename templates
- Bulk library actions
- Self-hosted advanced options
- Future: cloud backup destinations

## What we will not monetize

- Private account access
- Login / cookie features
- “Stealth” or anonymous viewing
- Mass scraping tools

## Future billing options

1. Google Play subscriptions
2. License keys for self-hosted users
3. Optional team plans

All gated through `EntitlementRepository` — swap `LocalDemoEntitlementRepository` for remote validation without UI rewrites.
