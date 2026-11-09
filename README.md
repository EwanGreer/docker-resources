# Docker Resources

Reusable Docker Compose configurations and Dockerfile templates for common services. Each subdirectory is a self-contained example.

## Stacks

| Directory | Contents |
|---|---|
| `go/` | Multi-stage Go Dockerfile with `production` and `development` (hot-reload + debugger) targets |
| `postgres/` | PostgreSQL + pgAdmin |
| `redis/` | Redis with persistent volume |
| `kafka/` | Kafka (KRaft mode) + Kafka UI + topic init container |
| `nats/` | NATS with JetStream + stream init container + nats-box |
| `networking/` | Caddy and Traefik reverse proxies with a whoami demo service |
| `observability/` | Grafana + Prometheus + Loki + Promtail + node-exporter |
| `localstack/` | LocalStack Pro |
| `ministack/` | MiniStack AWS emulator + Terraform example |

## Usage

Each stack runs through Docker Compose:

```bash
docker compose -f <directory>/compose.yml up -d
```

Most stacks accept environment variables for ports, credentials, and init data, for example `KAFKA_TOPICS="orders:3:1"` or `POSTGRES_PORT=5555`.

See [CLAUDE.md](CLAUDE.md) for full instructions, default credentials, and port overrides for every stack.
