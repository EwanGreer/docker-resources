# Observability Stack

Grafana + Prometheus + Loki + Promtail + node-exporter.

```bash
docker compose -f observability/compose.yml up -d
```

| Service | URL |
|---|---|
| Grafana | http://localhost:3000 (admin / admin) |
| Prometheus | http://localhost:9090 |
| Loki | http://localhost:3100 |

Two dashboards are provisioned automatically:

- **Node Metrics** — host CPU, memory, disk, load average, and network I/O
- **Container Logs** — live log stream, per-container log rate, and error/warn filter

Promtail ships logs from all running Docker containers automatically. To edit dashboards, modify the JSON files in `grafana/provisioning/dashboards/` — changes hot-reload within 30 seconds.

Override ports and credentials:

```bash
GRAFANA_PORT=3001 PROMETHEUS_PORT=9091 LOKI_PORT=3101 \
GF_SECURITY_ADMIN_PASSWORD=secret \
docker compose -f observability/compose.yml up -d
```

---

## Integrating a Go application

### 1. Expose `/metrics` from your app

```bash
go get github.com/prometheus/client_golang/prometheus
go get github.com/prometheus/client_golang/prometheus/promhttp
```

Register your metrics and mount the handler:

```go
import (
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promauto"
    "github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
    httpRequestsTotal = promauto.NewCounterVec(prometheus.CounterOpts{
        Name: "http_requests_total",
        Help: "Total HTTP requests.",
    }, []string{"method", "path", "status"})

    httpRequestDuration = promauto.NewHistogramVec(prometheus.HistogramOpts{
        Name:    "http_request_duration_seconds",
        Buckets: prometheus.DefBuckets,
    }, []string{"method", "path"})
)

http.Handle("/metrics", promhttp.Handler())
```

`promhttp.Handler()` also exports Go runtime metrics for free: GC pause times, goroutine count, heap size, etc.

### 2. Join the observability network

In your app's `compose.yml`, attach the service to the shared `observability` network:

```yaml
services:
  app:
    build: .
    ports:
      - "8080:8080"
    networks:
      - default
      - observability

networks:
  default:
  observability:
    name: observability
    external: true
```

The observability stack must be running first to create the network:

```bash
docker compose -f observability/compose.yml up -d
docker compose -f your-app/compose.yml up -d
```

### 3. Add a scrape job

Add a job to `observability/prometheus.yml`:

```yaml
  - job_name: go-app
    static_configs:
      - targets: ['app:8080']
    metrics_path: /metrics
```

Reload Prometheus without restarting:

```bash
curl -X POST http://localhost:9090/-/reload
```

Check `http://localhost:9090/targets` — your app should appear as `UP`.

### 4. Query your metrics in Grafana

Open `http://localhost:3000` and use **Explore** (Prometheus datasource) to query:

| What | PromQL |
|---|---|
| Request rate | `rate(http_requests_total[1m])` |
| Error rate | `rate(http_requests_total{status=~"5.."}[1m])` |
| p99 latency | `histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))` |
| Goroutines | `go_goroutines` |
| Heap in use | `go_memstats_heap_inuse_bytes` |
| GC pause (p99) | `histogram_quantile(0.99, rate(go_gc_duration_seconds_bucket[5m]))` |

From here you can save panels into a new dashboard or add a JSON file to `grafana/provisioning/dashboards/` to provision it automatically.
