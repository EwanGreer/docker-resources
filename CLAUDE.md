# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

A collection of reusable Docker Compose configurations and Dockerfile templates for common services. Each subdirectory is a self-contained example.

## Structure

- `go/` — Multi-stage Dockerfile for Go apps + compose with `production` and `development` targets
- `postgres/` — Compose for PostgreSQL + pgAdmin
- `redis/` — Compose for Redis with persistent volume
- `kafka/` — Compose for Kafka (KRaft mode) + Kafka UI + topic init container

## Go Template

The Go Dockerfile (`go/Dockerfile`) has four named stages:

| Stage | Base | Purpose |
|---|---|---|
| `base` | `golang:1.25` | Downloads modules, copies source |
| `builder` | `base` | Compiles to static binary (`CGO_ENABLED=0`) |
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
