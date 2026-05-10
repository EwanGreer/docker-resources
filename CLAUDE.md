# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

A collection of reusable Docker Compose configurations and Dockerfile templates for common services. Each subdirectory is a self-contained example.

## Structure

- `go/` — Multi-stage Dockerfile for Go apps + compose with `production` and `development` targets
- `postgres/` — Compose for PostgreSQL + pgAdmin
- `redis/` — Compose for Redis with persistent volume
- `kafka/` — Compose for Kafka (KRaft mode) + Kafka UI + topic init container
- `nats/` — Compose for NATS with JetStream, stream init container, and nats-box CLI container
- `observability/` — Compose for Grafana + Prometheus + Loki + Promtail + node-exporter

## Go Template

The Go Dockerfile (`go/Dockerfile`) has four named stages:

| Stage | Base | Purpose |
|---|---|---|
| `base` | `golang:1.25` | Downloads modules, copies `*.go *.toml *.sh` from root |
| `builder` | `base` | Compiles to static binary (`CGO_ENABLED=0`, `go build -o app ./`) |
| `production` | `distroless/static-debian12:nonroot` | Minimal runtime image |
| `development` | `base` | Installs `air` (hot-reload) + `dlv` (debugger) |

### Development workflow

The development container runs `docker-entrypoint.sh`, which generates a temporary `.air.toml` and launches `air` driving `dlv` on port `2345`. Key environment overrides:

```bash
APP_PKG=./cmd/server   # main package path inside the container
APP_BIN=/tmp/app       # output binary path
DLV_ADDR=0.0.0.0:2345 # Delve listen address (mapped in compose.yml)
AIR_DELAY_MS=500       # debounce rebuild delay (ms)
```

The source tree is bind-mounted into `/app`, so edits on the host trigger live rebuilds inside the container.

```bash
# Production image
docker compose -f go/compose.yml up production

# Development image (live reload + remote debug on :2345)
docker compose -f go/compose.yml up development
```

## Postgres

Default credentials: `root` / `password`. pgAdmin at `http://localhost:5433` (`admin@example.com` / `password`).

```bash
POSTGRES_PORT=5555 PG_ADMIN_PORT=5556 docker compose -f postgres/compose.yml up -d
```

Data persists in named volumes `postgres_data` and `pg_admin_data`.

## Redis

```bash
docker compose -f redis/compose.yml up -d
```

Listens on `6379`. Data persists in named volume `cache_data`.

## Kafka

Runs a single-node KRaft broker (no ZooKeeper) with Kafka UI at `http://localhost:8080`.

```bash
KAFKA_TOPICS="orders:3:1 payments:1:1" docker compose -f kafka/compose.yml up -d
```

`KAFKA_TOPICS` is a space-separated list in `name:partitions:replication` format — all fields after the name are optional and default to `1`. Topic creation is handled by the `kafka-init` container (`kafka-init-entrypoint.sh`), which runs once after the broker passes its healthcheck and exits.

Two Kafka listeners are configured:
- `PLAINTEXT://kafka:9092` — internal Docker network (used by kafka-ui and other containers in the same compose project)
- `EXTERNAL://localhost:19092` — host access

Override ports:
```bash
KAFKA_PORT=9092 KAFKA_UI_PORT=9090 docker compose -f kafka/compose.yml up -d
```

To re-run topic init after the stack is already up:
```bash
KAFKA_TOPICS="orders:3:1" docker compose -f kafka/compose.yml up --force-recreate kafka-init
```

## NATS

Runs a single-node NATS broker with JetStream enabled. Monitoring JSON at `http://localhost:8222`. No browser UI — use `nats-box` for introspection.

```bash
NATS_STREAMS="orders:orders.> payments:payments.>" docker compose -f nats/compose.yml up -d
```

`NATS_STREAMS` is a space-separated list of `name:subjects` pairs. The subjects field is optional and defaults to `<name>.>`. Stream creation is handled by the `nats-init` container, which runs once and exits.

Override ports:
```bash
NATS_PORT=4222 NATS_MONITOR_PORT=8222 docker compose -f nats/compose.yml up -d
```

`nats-box` is a persistent container with the `nats` CLI pre-configured to connect to the broker (`NATS_URL` is set automatically):
```bash
docker exec -it nats-box nats stream ls
docker exec -it nats-box nats pub orders.new "hello"
docker exec -it nats-box nats sub "orders.>"
```

To re-run stream init after the stack is already up:
```bash
NATS_STREAMS="orders:orders.>" docker compose -f nats/compose.yml up --force-recreate nats-init
```

## Observability

Runs Grafana, Prometheus, Loki, Promtail, and node-exporter. Grafana at `http://localhost:3000` (`admin` / `admin`). Prometheus at `http://localhost:9090`. Loki API at `http://localhost:3100`.

```bash
docker compose -f observability/compose.yml up -d
```

Override ports and credentials:
```bash
GRAFANA_PORT=3001 PROMETHEUS_PORT=9091 LOKI_PORT=3101 \
GF_SECURITY_ADMIN_PASSWORD=secret \
docker compose -f observability/compose.yml up -d
```

Two dashboards are provisioned automatically:
- **Node Metrics** — host CPU, memory, disk, load average, and network I/O via node-exporter
- **Container Logs** — live log stream, per-container log rate, and error/warn filter via Promtail + Loki

Promtail ships logs from all running Docker containers automatically. Dashboard JSON files live in `observability/grafana/provisioning/dashboards/` and hot-reload every 30 seconds — edit the JSON files directly rather than saving changes in the UI.

### Integrating another stack

The observability stack creates a Docker network named `observability`. Attach a service to it so Prometheus can scrape it by container name.

**1. In the other stack's `compose.yml`:**
```yaml
services:
  my-service:
    ...
    networks:
      - default
      - observability

networks:
  default:
  observability:
    name: observability
    external: true
```

**2. Add a scrape job to `observability/prometheus.yml`:**
```yaml
  - job_name: my-service
    static_configs:
      - targets: ['my-service:8080']
```

**3. Reload Prometheus without restarting:**
```bash
curl -X POST http://localhost:9090/-/reload
```
