# Self-Hosting

Run your own QuickSave resolver for full control over data flow.

## Quick start (Docker)

```bash
cd backend
cp .env.example .env
docker build -t quicksave-backend .
docker run -p 3000:3000 --env-file .env quicksave-backend
```

Optional Redis for shared rate limits and cache:

```bash
docker run -d --name quicksave-redis -p 6379:6379 redis:7-alpine
# Set REDIS_URL=redis://host.docker.internal:6379 in .env
```

## Endpoints

| Endpoint | Purpose |
|----------|---------|
| `GET /health` | Service + version + uptime |
| `GET /health/live` | Liveness probe |
| `GET /health/ready` | Readiness (Redis ping) |
| `GET /version` | Version only |
| `GET /health/metrics` | Protected metrics (see below) |
| `POST /resolve` | Resolve public Instagram URL |

## Environment variables

See `backend/.env.example`. Key settings:

- `RATE_LIMIT_MAX` — default 30/min (aligned with Render blueprint)
- `METRICS_PUBLIC=false` — require `METRICS_TOKEN` or `Authorization: Bearer`
- `SERVICE_VERSION` — reported in `/health`
- `ALLOWED_ORIGINS` — comma-separated browser origins allowed by CORS.
  **Required in production** for the Web PWA (browser API calls are blocked
  without it). Mobile apps and curl are not affected by CORS.

## Security notes

- Use HTTPS in production
- Do not expose metrics publicly without a token
- Do not log full user URLs (backend sanitizes for logs)
- No Instagram credentials — public content only
- CORS denies unknown origins in production (`ALLOWED_ORIGINS` allowlist);
  development mode (`NODE_ENV=development`) allows all origins
- CSP is enforced for the served Web PWA
- `BILLING_DEV_ACCEPT=1` is ignored when `NODE_ENV=production`

## Troubleshooting

| Symptom | Check |
|---------|-------|
| 503 metrics | Set `METRICS_PUBLIC=true` or provide `METRICS_TOKEN` |
| 429 rate limit | Lower client frequency or raise `RATE_LIMIT_MAX` |
| Redis errors | Set `CACHE_REDIS=0` or fix `REDIS_URL` |
| App can't connect | Use LAN IP, not `localhost`, from physical device |

## App configuration

Settings → Backend → Self-hosted → enter URL → Test connection.

Pro license keys are issued with `node scripts/generate-license-key.mjs`
(`--selfhost` for the self-hosted tier). Public demo keys (`QS-PRO-DEMO1`)
are for dev/review builds only.
