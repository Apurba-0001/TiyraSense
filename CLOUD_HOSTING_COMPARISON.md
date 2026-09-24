# Cloud Hosting Provider Comparison — TiyraSense Backend

> **Context:** TiyraSense needs to deploy a FastAPI + Uvicorn backend to the cloud. The database (PostgreSQL + PostGIS) is already hosted on Supabase Cloud, so we only need backend compute hosting. The target users are in India's North Eastern Region (NER).

---

## Quick Decision Matrix

| Provider | Monthly Cost | Setup Effort | India Region? | Cold Starts? | Auto-Deploy? | Best For |
|----------|-------------|-------------|---------------|-------------|-------------|----------|
| **Railway** | $5–15 | ⭐ Very Easy | ❌ No | ❌ No | ✅ GitHub | Fastest to production |
| **Render** | $13–15 | ⭐ Easiest | ❌ No (200-300ms) | ⚠️ Free tier only | ✅ GitHub | Simplest possible setup |
| **Fly.io** | $40–50 | ⭐⭐⭐ Complex | ❌ No | ❌ No | ✅ CLI | Overkill for current scale |
| **DO App Platform** | $5+ | ⭐⭐ Easy | ✅ Bangalore | ❌ No | ✅ GitHub | India latency + managed |
| **DO Droplet (VPS)** | $4+ | ⭐⭐⭐ Manual | ✅ Bangalore | ❌ No | ⚠️ Manual/CI | Cheapest + full control |

---

## Detailed Analysis

### 1. Railway — Best Balance of Simplicity + Features

**How it works:** Connect GitHub repo → Railway auto-builds and deploys your Docker container. Dashboard-based project management with visual service graph.

| Aspect | Details |
|--------|---------|
| **Cost** | Hobby plan: $5/mo (includes $5 credit). Backend + small overhead typically $6–15/mo total |
| **Database** | Not needed — we already use Supabase. Railway's PostgreSQL is optional |
| **Deployment** | Push to GitHub → auto-deploy. Zero configuration needed |
| **Regions** | US-West, US-East, EU-West, Asia-Southeast (Singapore) |
| **India Latency** | ~60-100ms from NER to Singapore |
| **Cold Starts** | None — services run 24/7 on Hobby plan |
| **HTTPS** | ✅ Automatic via `*.up.railway.app` |
| **Custom Domain** | ✅ Supported |
| **Environment Variables** | ✅ Built-in UI, per-environment |
| **Scaling** | Vertical (increase RAM/CPU) + horizontal (replicas on Pro) |

**Pros:**
- Fastest path from zero to production
- Visual dashboard is excellent for managing env vars
- Singapore region gives reasonable India latency
- Usage-based means you only pay for what you use
- Built-in logging and monitoring

**Cons:**
- No India data center (Singapore is closest)
- Costs can be unpredictable without billing limits
- No free tier (only trial credit)

**TiyraSense fit:** ⭐⭐⭐⭐⭐ Excellent. Just needs a `Dockerfile` + `railway.json`.

---

### 2. Render — Simplest Possible Setup

**How it works:** Connect GitHub → Render detects Python → auto-deploys. Heroku-like experience.

| Aspect | Details |
|--------|---------|
| **Cost** | Starter web service: $7/mo. Total with workspace: ~$13-15/mo |
| **Free tier** | Yes, but spins down after 15 min → 30-60s cold starts |
| **Regions** | US (Oregon, Ohio), EU (Frankfurt), Asia (Singapore) |
| **India Latency** | ~200-300ms (no India DC) |
| **Cold Starts** | Free tier: 30-60s. Paid: None |
| **HTTPS** | ✅ Automatic |

**Pros:**
- Simplest setup of all options
- Free tier for testing (with cold start caveat)
- Clear, predictable pricing

**Cons:**
- **No India region** — 200-300ms latency is noticeable for mobile users in NER
- Free database expires after 30 days
- Paid tier is more expensive than Railway for similar specs
- Cold starts on free tier make it unsuitable for SIH demo

**TiyraSense fit:** ⭐⭐⭐ Decent for quick prototyping, but latency to India is a concern.

---

### 3. Fly.io — Power Users & Edge Deployment

**How it works:** CLI-first. You create a `fly.toml`, build a Docker image, and deploy via `flyctl`.

| Aspect | Details |
|--------|---------|
| **Cost** | Backend: $2-6/mo. Managed Postgres: $38/mo. **Total: $40-50/mo** |
| **Complexity** | High — CLI, Docker, VM configuration required |
| **Regions** | 35+ global regions including Mumbai (India) |
| **India Latency** | ~20-40ms (Mumbai region available!) |
| **Cold Starts** | Configurable — can scale to zero but adds latency |

**Pros:**
- **Mumbai region** — best latency for India
- Most granular control
- Edge deployment if needed later

**Cons:**
- **Expensive** — managed Postgres alone is $38/mo (though we don't need it since we use Supabase)
- CLI-first means more DevOps effort
- Steeper learning curve
- Overkill for current project scale

**TiyraSense fit (without their DB):** ⭐⭐⭐⭐ If using only compute (no managed DB since we have Supabase), cost drops to ~$2-6/mo and Mumbai latency is excellent. But setup complexity is higher.

---

### 4. DigitalOcean App Platform — India Region + Managed

**How it works:** Connect GitHub → auto-build and deploy. PaaS experience.

| Aspect | Details |
|--------|---------|
| **Cost** | Starting $5/mo (1 vCPU, 512MB RAM) |
| **Regions** | ✅ **Bangalore, India** |
| **India Latency** | ~10-30ms from NER to Bangalore |
| **Cold Starts** | None on paid tier |
| **HTTPS** | ✅ Automatic |
| **Auto-Deploy** | ✅ GitHub push-to-deploy |

**Pros:**
- **Bangalore data center** — lowest possible latency for NER users
- Push-to-deploy from GitHub
- Predictable pricing
- DigitalOcean is well-known and reliable

**Cons:**
- Less feature-rich dashboard than Railway
- Additional services (databases, monitoring) cost extra
- 512MB RAM on $5 tier might be tight for FastAPI + Uvicorn workers

**TiyraSense fit:** ⭐⭐⭐⭐ Good balance. India region is a significant advantage for NER users.

---

### 5. DigitalOcean Droplet (VPS) — Cheapest + Full Control

**How it works:** Provision a Linux VM, SSH in, install Python/Uvicorn/Nginx manually.

| Aspect | Details |
|--------|---------|
| **Cost** | $4/mo (1 vCPU, 512MB RAM, 500GB bandwidth) |
| **Regions** | ✅ **Bangalore, India** |
| **India Latency** | ~10-30ms from NER to Bangalore |
| **Setup** | Manual: install Python, Nginx, systemd service, TLS via Let's Encrypt |
| **Auto-Deploy** | Manual or GitHub Actions CI/CD |
| **Scaling** | Manual (resize droplet or add load balancer) |

**Pros:**
- **Cheapest option** — $4/mo
- **Bangalore** data center
- Full root access — can run anything
- Can co-locate backend + OSRM + any other service on same VM

**Cons:**
- Most manual setup work (Nginx, systemd, TLS, firewall)
- You are responsible for security updates, monitoring, backups
- No auto-deploy without setting up CI/CD
- More operational burden

**TiyraSense fit:** ⭐⭐⭐⭐ Best value if you're comfortable with Linux server administration.

---

## TiyraSense-Specific Considerations

### What We Need
1. **Backend compute only** — database is on Supabase, photos on Cloudinary
2. **Always-on** — mobile/web connect any time, not just during demos
3. **HTTPS** — required for mobile app and dashboard
4. **SSE/WebSocket support** — needed for real-time push (planned Phase 5)
5. **Environment variables** — for secrets management
6. **Low latency to India/NER** — target users are in the North East

### What We DON'T Need
- Managed PostgreSQL (already on Supabase)
- Managed Redis (no background workers yet)
- Multi-region deployment (single region is fine)
- Auto-scaling (low traffic during SIH evaluation)

### Latency Matters
For NER (Assam, Meghalaya, etc.), the closest data centers are:
- **Bangalore** (~10-30ms) — DigitalOcean
- **Mumbai** (~20-40ms) — Fly.io
- **Singapore** (~60-100ms) — Railway
- **US/EU** (~200-300ms) — Render

---

## Recommendation

### For Fastest Setup (SIH Demo Priority): **Railway**
- Deploy in under 10 minutes
- Singapore region gives acceptable ~60-100ms latency
- $5-15/mo is budget-friendly
- Visual dashboard makes env var management easy
- All future phases (SSE, monitoring) are straightforward

### For Lowest Cost + Best Latency: **DigitalOcean Droplet ($4/mo in Bangalore)**
- Best latency for NER users (~10-30ms)
- Cheapest monthly cost
- Full control means you can also run OSRM routing engine on same VM later
- Requires more initial setup (Nginx, TLS, systemd)
- Good for long-term production

### For Balance of Both: **DigitalOcean App Platform ($5/mo in Bangalore)**
- India region with managed deployment
- Push-to-deploy from GitHub
- No server administration needed
- Slightly more expensive than raw Droplet but much less operational work

> [!IMPORTANT]
> **My recommendation for TiyraSense:** Start with **Railway** (Singapore) for fastest time-to-production during the SIH evaluation phase. The ~80ms latency is acceptable for demos. Later, if production latency requirements tighten, migrate to **DigitalOcean Bangalore** for optimal NER performance.
>
> Alternatively, if you prefer India proximity from the start, go with **DigitalOcean App Platform** ($5/mo, Bangalore). It's nearly as easy as Railway and gives the best latency.
