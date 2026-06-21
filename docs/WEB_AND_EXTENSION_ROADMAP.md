# Web & Extension Roadmap

Mobile-first today; web and extension are **preparation only** in v1.2.

## Future architecture

```
┌─────────────────┐     ┌──────────────────┐
│ Chrome Extension│────▶│ QuickSave Backend │
│ (share capture) │     │ POST /resolve     │
└─────────────────┘     └────────┬─────────┘
                                 │
┌─────────────────┐              │
│ Web Dashboard   │◀─────────────┘
│ (PWA / Flutter) │   library sync API (future)
└─────────────────┘
```

## Web dashboard (PWA)

- View library metadata (sync required)
- Export / backup management
- Self-hosted backend configuration
- No private scraping from web

## Chrome extension

Shipped as **Chrome MV3** in `extension/`:

- Floating **QuickSave** button on post / reel / TV pages (user click)
- Toolbar popup — save current tab
- Context menu on Instagram links
- Opens Web dashboard with `?url=` (no background crawl)
- Settings: dashboard URL + self-hosted backend reference

Load unpacked: see `extension/README.md`.

## Library sync (future)

- End-to-end encrypted metadata sync
- Optional self-hosted sync server
- Conflict resolution for collections

## Flutter Web

Web dashboard PWA ships as a **companion** (not full mobile port):

- Resolve preview via configured backend
- Import/export library **metadata** (JSON from Android → CSV in browser)
- Self-hosted / hosted backend settings + health check
- `flutter build web` in CI; backend serves `build/web` static files

Full library sync and file download on web remain future work.

## Non-goals

- Web-based mass profile scraper
- Anonymous story viewer
- Account login flow
