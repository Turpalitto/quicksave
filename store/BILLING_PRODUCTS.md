# Google Play Billing — Pro subscriptions

Create these **subscription** products in Play Console (same `applicationId`: `com.quicksave.app`).

| Product ID | Suggested type | App constant |
|------------|----------------|--------------|
| `quicksave_pro_monthly` | Auto-renewing subscription | `BillingConstants.proPersonalMonthly` |
| `quicksave_pro_yearly` | Auto-renewing subscription | `BillingConstants.proPersonalYearly` |

## Setup steps

1. Play Console → **Monetize** → **Products** → **Subscriptions**
2. Create both IDs exactly as above (lowercase, underscores)
3. Set pricing, free trial / intro offer if desired
4. Activate products
5. Add **License testers** (internal testing track)
6. Upload AAB to **Internal testing**
7. On device: Settings → Pro → **Subscribe with Google Play** / **Restore purchases**

## License keys (self-hosted / review)

Still supported alongside Play:

- Demo: `QS-PRO-DEMO1`, `QS-PRO-DEMO2026`, `QS-PRO-REVIEW1`
- Self-hosted tier: `QS-PRO-SHOSTxxxx`

## Server verification (optional)

Backend stub: `POST /billing/play/verify`

```env
BILLING_PLAY_VERIFY=1
BILLING_DEV_ACCEPT=1   # dev only — accepts all tokens
```

Production: implement Google Play Developer API verification (not in v1.3.1 stub).
