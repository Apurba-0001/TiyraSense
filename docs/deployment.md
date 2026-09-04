# Deployment & Runtime Environment Specification — TiyraSense

**Document Status:** FINALIZED Specification (Phase 1)  
**Authoritative Decision:** D-014 (Local Containerized Runtime with Docker Compose & PostGIS)

---

## 1. Local Evaluation Architecture (Docker Compose)

For the SIH 2026 Selection Sprint and jury evaluation, TiyraSense runs in a self-contained, offline-capable environment orchestrated via Docker Compose:

```
[Developer Machine / Jury Evaluation Laptop]
                     |
+--------------------v--------------------------------------------------+
|                         Docker Network: tiyrasense-net                |
|                                                                       |
|   +--------------------------+          +-------------------------+   |
|   |   tiyrasense-web         |          |   tiyrasense-backend    |   |
|   |   React + MapLibre GL    |          |   FastAPI + Python 3.11 |   |
|   |   Port: 5173 (or 80)     |          |   Port: 8000            |   |
|   +------------+-------------+          +------------+------------+   |
|                |                                     |                |
|                +------------------+------------------+                |
|                                   |                                   |
|                                   v                                   |
|                     +---------------------------+                     |
|                     |   tiyrasense-db           |                     |
|                     |   PostgreSQL 16 + PostGIS |                     |
|                     |   Port: 5432              |                     |
|                     |   Volume: tiyrasense_pgdata                     |
|                     +---------------------------+                     |
+-----------------------------------------------------------------------+
```

---

## 2. Docker Compose Configuration Structure

> [!NOTE]
> **Environment Modes:** In the local sprint development setup, `docker-compose.yml` provides the containerized PostgreSQL 16 + PostGIS 3.4 spatial database (`tiyrasense-db`), while the FastAPI backend runs on the host via Python `.venv` and the React frontend runs via Vite for sub-second hot reloading. The complete 3-service configuration below represents the target evaluation and production deployment.

```yaml
version: '3.8'

services:
  db:
    image: postgis/postgis:16-3.4
    container_name: tiyrasense-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-tiyrasense_user}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-tiyrasense_secure_pass_2026}
      POSTGRES_DB: ${POSTGRES_DB:-tiyrasense_db}
    ports:
      - "5432:5432"
    volumes:
      - tiyrasense_pgdata:/var/lib/postgresql/data
      - ./backend/migrations/init.sql:/docker-entrypoint-initdb.d/init.sql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U tiyrasense_user -d tiyrasense_db"]
      interval: 5s
      timeout: 5s
      retries: 5
    networks:
      - tiyrasense-net

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: tiyrasense-backend
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      DATABASE_URL: postgresql+asyncpg://${POSTGRES_USER:-tiyrasense_user}:${POSTGRES_PASSWORD:-tiyrasense_secure_pass_2026}@db:5432/${POSTGRES_DB:-tiyrasense_db}
      JWT_SECRET_KEY: ${JWT_SECRET_KEY:-local_dev_jwt_secret_change_in_production}
      GEMINI_API_KEY: ${GEMINI_API_KEY:-}
      DATA_ENVIRONMENT: "LOCAL_DEV"
    ports:
      - "8000:8000"
    volumes:
      - ./backend:/app
    networks:
      - tiyrasense-net

  web:
    build:
      context: ./web
      dockerfile: Dockerfile
    container_name: tiyrasense-web
    restart: unless-stopped
    ports:
      - "5173:5173"
    environment:
      - VITE_API_BASE_URL=http://localhost:8000/api/v1
    depends_on:
      - backend
    networks:
      - tiyrasense-net

volumes:
  tiyrasense_pgdata:

networks:
  tiyrasense-net:
    driver: bridge
```

---

## 3. Quickstart & Verification Sequence

### Prerequisites
- Docker & Docker Compose installed.
- Python 3.11+ installed locally for testing/script execution.

### Step-by-Step Launch
```bash
# 1. Copy environment template
cp .env.example .env

# 2. Launch database and microservices in background
docker compose up -d

# 3. Verify PostgreSQL + PostGIS initialization
docker compose exec db psql -U tiyrasense_user -d tiyrasense_db -c "SELECT PostGIS_Version();"

# 4. Seed Guwahati-Shillong corridor spatial segments
python scripts/seed_corridor_data.py

# 5. Run end-to-end integration test
pytest tests/scenarios/test_canonical_evaluation.py -v
```

---

## 4. Resource Allocation & Memory Footprint

To ensure smooth operation on standard developer laptops and battery-powered field testing notebooks:

| Container | CPU Limit | RAM Limit | Target Steady-State RAM |
|---|:---:|:---:|:---:|
| `tiyrasense-db` | 1.0 core | 1024 MB | $\sim 280\text{ MB}$ |
| `tiyrasense-backend` | 1.0 core | 768 MB | $\sim 190\text{ MB}$ |
| `tiyrasense-web` | 0.5 core | 512 MB | $\sim 120\text{ MB}$ |
| **Total System Footprint** | **2.5 cores** | **2.3 GB** | **$< 600\text{ MB}$** |

---

## 5. Production Cloud Deployment Roadmap (Post-Selection)

When transitioning from local evaluation to government production deployment:
1. **Infrastructure:** Kubernetes (K8s) or Docker Swarm deployed on MeitY-empanelled cloud infrastructure (NIC / AWS India / Azure India) ensuring sovereign data residency within India.
2. **Database:** Managed High-Availability PostgreSQL with PostGIS extension, read replicas, and daily automated encrypted spatial backups.
3. **Edge Caching:** CloudFront or Cloudflare CDN terminating TLS 1.3 and caching static OpenStreetMap raster tiles.
4. **Security Hardening:** Automatic container vulnerability scanning, non-root execution, secret management via HashiCorp Vault or AWS Secrets Manager.
