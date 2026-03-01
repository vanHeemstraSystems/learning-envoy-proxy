# Task 03-01 — Prometheus + Grafana Stack

> **Story:** [Prometheus Metrics](../stories/story-03-01-prometheus-metrics.md)  
> **Effort:** ~45 minutes  
> **Prerequisites:** Docker Compose

---

## Objective

Stand up a full observability stack — Envoy, Prometheus, and Grafana — and build a dashboard with Envoy's golden signals.

---

## Step 1: Project Structure

```
observability-stack/
├── docker-compose.yml
├── envoy/
│   └── envoy.yaml
├── prometheus/
│   └── prometheus.yml
└── grafana/
    └── provisioning/
        ├── datasources/
        │   └── prometheus.yml
        └── dashboards/
            └── envoy.json
```

---

## Step 2: Docker Compose

```yaml
# docker-compose.yml
version: "3.8"
services:
  envoy:
    image: envoyproxy/envoy:v1.29-latest
    volumes:
      - ./envoy/envoy.yaml:/etc/envoy/envoy.yaml
    ports:
      - "10000:10000"
      - "9901:9901"

  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"
    command:
      - "--config.file=/etc/prometheus/prometheus.yml"
      - "--storage.tsdb.path=/prometheus"
      - "--web.console.libraries=/usr/share/prometheus/console_libraries"
      - "--web.console.templates=/usr/share/prometheus/consoles"

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=atlas123
    volumes:
      - ./grafana/provisioning:/etc/grafana/provisioning
    depends_on:
      - prometheus

  backend:
    image: kennethreitz/httpbin
    ports:
      - "8080:80"
```

---

## Step 3: Prometheus Scrape Config

```yaml
# prometheus/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'envoy'
    static_configs:
      - targets: ['envoy:9901']
    metrics_path: '/stats/prometheus'
    scrape_interval: 10s

  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
```

---

## Step 4: Grafana Datasource Provisioning

```yaml
# grafana/provisioning/datasources/prometheus.yml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    url: http://prometheus:9090
    isDefault: true
    access: proxy
```

---

## Step 5: Envoy Config

Use the static config from Task 02-01, pointing the cluster to `backend:80`.

---

## Step 6: Start the Stack

```bash
docker compose up -d

# Generate some traffic
for i in {1..50}; do curl -s http://localhost:10000/ip > /dev/null; done
for i in {1..10}; do curl -s http://localhost:10000/status/500 > /dev/null; done
```

---

## Step 7: Build the Grafana Dashboard

Open http://localhost:3000 (admin/atlas123) and create panels:

| Panel Title | Metric | Visualization |
|---|---|---|
| Request Rate | `rate(envoy_http_downstream_rq_total[1m])` | Time series |
| Error Rate (5xx) | `rate(envoy_http_downstream_rq_xx{envoy_response_code_class="5"}[1m])` | Time series |
| Success Rate % | `(1 - rate(envoy_http_downstream_rq_xx{envoy_response_code_class="5"}[5m]) / rate(envoy_http_downstream_rq_total[5m])) * 100` | Stat |
| P99 Latency (ms) | `histogram_quantile(0.99, rate(envoy_http_downstream_rq_time_bucket[5m]))` | Time series |
| Active Connections | `envoy_http_downstream_cx_active` | Stat |
| Upstream Health | `envoy_cluster_membership_healthy` | Stat |

---

## Verification

- [ ] Prometheus scrapes Envoy at `http://envoy:9901/stats/prometheus`
- [ ] Grafana dashboard shows request rate and error rate
- [ ] P99 latency panel shows response time histogram
- [ ] Active connections gauge updates in real time
