# QuickSave Browser Extension (Chrome MV3)

Privacy-first companion for saving **public** Instagram links you explicitly open or click.

## Features

- **Floating button** on post / reel / TV pages (`/p/`, `/reel/`, `/tv/`)
- **Toolbar popup** — save the current tab
- **Context menu** — right-click an Instagram link → Save to QuickSave
- Opens **QuickSave Web** with `?url=` for resolve preview (no background crawling)

## Install (development)

1. Open `chrome://extensions`
2. Enable **Developer mode**
3. **Load unpacked** → select the `extension/` folder in this repo
4. Open extension **Settings** to set your web dashboard URL (default: hosted QuickSave)

## Settings

| Key | Purpose |
|-----|---------|
| Web dashboard URL | Where `?url=` resolve tabs open |
| Backend mode / URL | Reference for self-hosted users (sync with Web dashboard settings) |

## Privacy

- No Instagram login or cookies
- No automatic mass extraction — only user clicks
- Only normalized public post/reel URLs are forwarded

## Tests

```bash
cd extension
node --test test/shared.test.js
```

## Store packaging (future)

Zip the `extension/` folder contents (not the parent repo). Icons are in `extension/icons/`.
