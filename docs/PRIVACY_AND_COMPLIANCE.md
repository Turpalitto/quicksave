# Privacy & Compliance

## Principles

1. **Public content only** — user-initiated via Share Intent or pasted URL
2. **No Instagram login** — no cookies, no session hijacking
3. **Local-first** — history and files on device; optional self-hosted resolver
4. **No tracking** — diagnostics are local; no third-party analytics by default
5. **Creator respect** — export attribution, no “download private” marketing

## Data collected

| Data | Where | Purpose |
|------|-------|---------|
| Saved media metadata | Device (SharedPreferences) | Library |
| Downloaded files | Device storage / Gallery | User archive |
| Resolver requests | Your backend (hosted or self-hosted) | URL → media URL |

Backend logs use **sanitized URLs** (host + path hash), not full links.

## Permissions

- Storage / Gallery — save files user requested
- Notifications — download completion
- Network — resolve and download public media

## Store compliance

See `store/privacy_policy.md` and `store/RELEASE_CHECKLIST.md`.

## User responsibilities

Users must only save content they have rights to use. QuickSave does not bypass paywalls, privacy settings, or platform ToS.
