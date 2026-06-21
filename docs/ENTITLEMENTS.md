# Entitlements

## Tiers

| Tier | Features |
|------|----------|
| **Free** | Basic downloads, history, basic collections |
| **Pro Personal** | Watchlist, ZIP/JSON/CSV export, smart folders, filename templates, bulk actions, cloud backup |
| **Pro Self-Hosted** | Pro + advanced self-hosted settings |
| **Team** (future) | Shared collections, sync |

## Implementation

- `EntitlementTier` — `lib/features/settings/domain/entitlement.dart`
- `EntitlementRepository` — `CompositeEntitlementRepository` (Play + license keys)
- `PlayBillingService` — Google Play subscriptions (`in_app_purchase`)
- `EntitlementService` — bootstrap + sync to `AppSettings.isPro`
- `EntitlementNotifier` — Riverpod UI layer

## Billing sources

| Source | Description |
|--------|-------------|
| **Google Play** | `quicksave_pro_monthly` / `quicksave_pro_yearly` subscriptions |
| **License key** | `QS-PRO-XXXX` format; self-hosted uses `QS-PRO-SHOSTXXXX` |
| **Demo keys** | `QS-PRO-DEMO1`, `QS-PRO-DEMO2026`, `QS-PRO-REVIEW1` |

## Server verification (optional)

`POST /billing/play/verify` on backend — enable with `BILLING_PLAY_VERIFY=1`.  
Dev shortcut: `BILLING_DEV_ACCEPT=1`. Client skips server call failure when endpoint returns 501.

## Gating philosophy

Soft paywall: free users keep core value. Pro unlocks organization, automation, export, and backup — not basic saving.
