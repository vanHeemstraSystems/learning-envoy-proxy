# Story 03-01 — Prometheus Metrics & Admin API

> **Flow:** [Observability](../flows/flow-03-observability.md)  
> **Effort:** ~45 minutes  
> **Task:** [Task 03-01 — Prometheus + Grafana](../tasks/task-03-01-prometheus-grafana.md)

---

## Envoy's Stats System

Envoy generates thousands of metrics, organized into three types:

| Type | Description | Example |
|---|---|---|
| **Counter** | Monotonically increasing integer | `http.ingress_http.downstream_rq_total` |
| **Gauge** | Current value (can go up/down) | `cluster.backend.upstream_cx_active` |
| **Histogram** | Latency/size distributions | `http.ingress_http.downstream_rq_time` |

---

## Admin API Stats Endpoint

```bash
# Raw stats (Envoy format)
curl http://localhost:9901/stats

# Prometheus format
curl http://localhost:9901/stats/prometheus

# Filter by prefix
curl "http://localhost:9901/stats?filter=http"

# JSON format
curl "http://localhost:9901/stats?format=json"
```

---

## Key Metrics to Monitor

### HTTP Metrics
```
# Request rate
envoy_http_downstream_rq_total

# Success rate (non-5xx)
envoy_http_downstream_rq_xx{envoy_response_code_class="2"}

# Error rate
envoy_http_downstream_rq_xx{envoy_response_code_class="5"}

# Request latency (p50, p95, p99)
envoy_http_downstream_rq_time_bucket
```

### Cluster (Upstream) Metrics
```
# Active connections to upstream
envoy_cluster_upstream_cx_active{envoy_cluster_name="backend"}

# Upstream request success/failure
envoy_cluster_upstream_rq_total{envoy_cluster_name="backend"}
envoy_cluster_upstream_rq_xx{envoy_cluster_name="backend", envoy_response_code_class="5"}

# Circuit breaker open
envoy_cluster_circuit_breakers_default_cx_open{envoy_cluster_name="backend"}

# Upstream latency
envoy_cluster_upstream_rq_time_bucket{envoy_cluster_name="backend"}
```

### Listener Metrics
```
# Active downstream connections
envoy_listener_downstream_cx_active

# Connection rate limit hits
envoy_listener_downstream_cx_overflow
```

---

## Prometheus Scrape Configuration

```yaml
# Envoy bootstrap: enable stats on port 9901 (already default)
admin:
  address:
    socket_address:
      address: 0.0.0.0
      port_value: 9901

# Also configure a dedicated stats sink for push-based metrics
stats_sinks:
  - name: envoy.stat_sinks.metrics_service
    typed_config:
      "@type": type.googleapis.com/envoy.config.metrics.v3.MetricsServiceConfig
      grpc_service:
        envoy_grpc:
          cluster_name: metrics_cluster
```

```yaml
# prometheus.yml scrape config
scrape_configs:
  - job_name: 'envoy'
    static_configs:
      - targets: ['localhost:9901']
    metrics_path: '/stats/prometheus'
    scrape_interval: 15s
```

---

## Grafana Dashboard

**Golden Signal panels to create:**

| Panel | Query |
|---|---|
| Request Rate | `rate(envoy_http_downstream_rq_total[1m])` |
| Error Rate | `rate(envoy_http_downstream_rq_xx{envoy_response_code_class="5"}[1m])` |
| P99 Latency | `histogram_quantile(0.99, rate(envoy_http_downstream_rq_time_bucket[5m]))` |
| Active Connections | `envoy_http_downstream_cx_active` |
| Circuit Breaker | `envoy_cluster_circuit_breakers_default_cx_open` |

---

## Summary

Envoy emits comprehensive metrics at the `/stats/prometheus` admin endpoint. Scraping this with Prometheus and visualizing with Grafana gives you full golden-signal observability for all traffic passing through the proxy.

---

## Knowledge Check

1. What are the three types of Envoy stats and how do they differ?
2. Which admin endpoint returns Prometheus-format metrics?
3. What PromQL query would you use to calculate the HTTP error rate?
4. What does the `circuit_breakers_default_cx_open` metric indicate?
