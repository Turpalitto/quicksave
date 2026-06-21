# QuickSave — Privacy Policy

**Last updated:** June 21, 2026

QuickSave helps you download **public** Instagram media you explicitly choose to save.

## Data controller

For hosted resolver usage, the operator of the QuickSave backend is the data controller for resolver request metadata. For self-hosted mode, **you** are the controller of URLs processed by your server.

## Legal basis (GDPR)

| Processing | Legal basis |
| --- | --- |
| Resolving URLs you submit | Legitimate interest / contract (provide the service you requested) |
| Local history & settings | Your device storage — no cloud account |
| Optional notifications | Consent (Android runtime permission) |
| Abuse prevention logs (hosted) | Legitimate interest (security, rate limiting) |

## What we collect

- **URLs you share or paste** — sent to the resolver to obtain public media links.
- **App settings, download history, collections** — stored locally on your device only.
- **Hosted resolver telemetry** — request counts, success rate, IP (for rate limiting), URL hash — **not** downloaded file contents.
- **We do not** require Instagram login or collect passwords.

## Retention

| Data | Retention |
| --- | --- |
| Local history / settings | Until you clear data or uninstall |
| Hosted resolver logs | Up to 30 days (operational logs) |
| Redis resolve cache | Default 10 minutes TTL |
| Downloaded media files | On device until you delete them |

## Your rights

You may request access, correction, or deletion of hosted resolver logs tied to your IP/session by emailing **support@quicksave.app**. Local data can be cleared in **Settings → Clear history** or by uninstalling the app.

## QuickSave Cloud (hosted resolver)

When using the default cloud resolver, your Instagram URL is transmitted to our server only to resolve public media. We do not store downloaded files on our servers.

## Self-hosted mode (Pro)

In self-hosted mode, URLs are sent **only** to the backend URL you configure. No data is sent to QuickSave Cloud unless you switch back to hosted mode.

## Telemetry disclosure

The app does not include third-party analytics SDKs. Hosted backend exposes aggregate metrics at `/health/metrics` for operators (success rate, error counts) — not user profiles.

## Permissions

- **Internet** — resolve and download media
- **Notifications** — download completion (optional)
- **Storage / Media** — save files to Gallery when enabled

## Children's privacy

QuickSave is not directed at children under 13.

## Contact

support@quicksave.app

## Changes

We may update this policy. Material changes will be reflected in the app and store listing.
