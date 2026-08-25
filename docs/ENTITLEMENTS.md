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
| **License key** | Checksummed keys issued via `scripts/generate-license-key.mjs` |
| **Demo keys** | `QS-PRO-DEMO1`, `QS-PRO-DEMO2026`, `QS-PRO-REVIEW1` (dev/review only) |

### License key format (v2, checksummed)

```
Personal:   QS-PRO-PAYLOAD-CC    # PAYLOAD = [A-Z0-9]{6,10}
Self-host:  QS-PRO-SHOSTPAYLOAD-CC
CC = 2-char checksum over the tier-salted payload (see ProService.checksumFor)
```

Legacy checksum-less keys (`QS-PRO-XXXX`) are no longer accepted for new
activations; already activated devices are unaffected. Issue real keys with:

```bash
node scripts/generate-license-key.mjs            # personal
node scripts/generate-license-key.mjs --selfhost # self-hosted tier
```

## Server verification

`POST /billing/play/verify` on backend — enable with `BILLING_PLAY_VERIFY=1`.
Dev shortcut: `BILLING_DEV_ACCEPT=1` (**ignored in production**).

Client semantics (`RemoteVerification`):
- `verified` — backend confirmed the purchase
- `notConfigured` — backend returned 501 or no backend URL set → fall back to
  the local Google Play purchase state
- `invalid` — backend rejected (or errored) → Pro is NOT granted

An unconfigured backend is never treated as a successful verification.

## Gating philosophy

Soft paywall: free users keep core value. Pro unlocks organization, automation, export, and backup — not basic saving.
