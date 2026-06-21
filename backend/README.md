# QuickSave Backend

Express API for resolving public Instagram URLs into downloadable media metadata.

## Quick start

```bash
cd backend
npm install
npm start
```

Server: `http://localhost:3000`

Copy `.env.example` to `.env` for production tuning.

## Docker

```bash
docker build -t quicksave-backend .
docker run -p 3000:3000 quicksave-backend
```

## Endpoints

### `GET /health`

```json
{ "ok": true, "service": "quicksave-backend", "version": "1.0.0", "uptime": 123 }
```

### `GET /health/ready`

```json
{ "ok": true, "ready": true, "redis": "disabled|ok|error" }
```

### `GET /health/metrics`

Resolver success rate and failure breakdown (alert when successRate &lt; 70% after 20+ requests).

## Deploy (Render)

1. Push repo to GitHub.
2. Render → **New Blueprint** → point at `backend/render.yaml`.
3. After deploy, copy service URL → set `hostedBackendUrl` in Flutter `app_constants.dart`.
4. Optional: attach Redis from blueprint for shared cache/rate limit.

See also [`render.yaml`](render.yaml) and [`store/RELEASE_CHECKLIST.md`](../store/RELEASE_CHECKLIST.md).

## Endpoints (resolve)

### `POST /resolve`

**Request:**

```json
{
  "url": "https://www.instagram.com/reel/ABC123/",
  "cursor": "optional-profile-pagination-cursor",
  "userId": "optional-instagram-user-id-for-pagination"
}
```

**Success (200) — collection response:**

```json
{
  "ok": true,
  "type": "single|carousel|story|highlight|profile",
  "items": [
    {
      "id": "ABC123_0",
      "index": 0,
      "mediaType": "video|image",
      "mediaUrl": "https://...",
      "thumbnailUrl": "https://...",
      "fileName": "quicksave_ABC123.mp4",
      "duration": 12,
      "width": 720,
      "height": 1280,
      "postUrl": "https://www.instagram.com/reel/ABC123/",
      "needsResolve": false,
      "qualities": [{ "url": "...", "width": 720, "height": 1280, "label": "720p" }]
    }
  ],
  "itemCount": 1,
  "videoCount": 1,
  "imageCount": 0,
  "author": "username",
  "shortcode": "ABC123",
  "videoUrl": "https://...",
  "fileName": "quicksave_ABC123.mp4",
  "userId": "12345",
  "nextCursor": "cursor-for-next-page",
  "hasMore": true
}
```

Top-level `videoUrl` / `fileName` remain for backward compatibility with single-item responses.

**Errors:**

| HTTP | error |
|------|-------|
| 400 | `invalid_url`, `invalid_json` |
| 403 | `private` |
| 404 | `not_found` |
| 413 | `payload_too_large` |
| 429 | `rate_limited` |
| 502 | `resolver_failed` |
| 500 | `internal` |

## Supported URL types

- Posts: `/p/`, `/reel/`, `/tv/`
- Stories: `/stories/user/id`
- Highlights: `/stories/highlights/id`
- Profiles: `instagram.com/username` (grid + pagination via `cursor` + `userId`)

## Environment variables

See [`.env.example`](.env.example):

- `PORT`, `NODE_ENV`, `TRUST_PROXY`
- `RATE_LIMIT_MAX`, `RATE_LIMIT_WINDOW_MS`
- `REQUEST_TIMEOUT_MS`, `RESOLVE_DEADLINE_MS`
- `CACHE_TTL_MS`, `CACHE_MAX_ENTRIES`, `UPSTREAM_POOL_SIZE`
- `CACHE_REDIS` — set to `0` to disable Redis resolve cache while keeping rate limiting
- `REDIS_URL` — optional Redis for shared rate limiting and resolve cache (multi-instance)
- `LOG_LEVEL`

## Architecture

- `src/routes/resolve.js` — HTTP layer
- `src/services/instagramResolver.js` — multi-strategy resolver with cache + deadline
- `src/services/mediaCollection.js` — carousel / story / highlight extraction
- `src/services/profileExtractor.js` — profile grid + feed pagination
- `src/services/resolveCache.js` — L1 in-memory LRU + optional L2 Redis cache
- `src/redisClient.js` — shared Redis connection
- `src/services/htmlParseUtils.js` — shared JSON/HTML helpers

## Limits

- Public content only — no login, no private accounts
- Rate limit: 30 req/min/IP (configurable)
- Resolve cache TTL: 10 min default
- Instagram markup changes may break scraping — tests help catch regressions

## Tests

```bash
npm test
```
