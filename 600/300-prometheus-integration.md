# Prometheus Integration

## Envoy's Stats Endpoint

Envoy exposes all statistics at the `/stats` endpoint of the admin API. By default this returns a text format. For Prometheus scraping, use:

```
GET http://envoy-admin:9901/stats/prometheus
```

This returns all stats in the Prometheus text exposition format.

## Enabling Admin Endpoint

```yaml
admin:
  address:
    socket_address:
      address: 0.0.0.0   # Or 127.0.0.1 for local-only access
      port_value: 9901
```

## Kubernetes PodMonitor (Prometheus Operator)

To scrape Envoy sidecars automatically in Kubernetes with the Prometheus Operator:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: envoy-stats
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: my-service   # Matches pods with Envoy sidecar
  podMetricsEndpoints:
    - port: envoy-admin
      path: /stats/prometheus
      interval: 15s
```

## Key Metrics to Monitor

**Upstream health**:
- `envoy_cluster_upstream_rq_total` — total upstream requests
- `envoy_cluster_upstream_rq_5xx` — 5xx errors from upstream
- `envoy_cluster_upstream_cx_connect_fail` — connection failures

**Downstream performance**:
- `envoy_http_downstream_rq_total` — total requests received
- `envoy_http_downstream_rq_time_bucket` — request latency histogram

**Circuit breakers**:
- `envoy_cluster_upstream_rq_pending_overflow` — requests rejected by circuit breaker
- `envoy_cluster_upstream_cx_overflow` — connections rejected by circuit breaker

## Useful Prometheus Queries

```promql
# HTTP error rate (5xx) per cluster
rate(envoy_cluster_upstream_rq_5xx[5m]) / rate(envoy_cluster_upstream_rq_total[5m])

# P99 request latency to a specific upstream cluster
histogram_quantile(0.99,
  rate(envoy_cluster_upstream_rq_time_bucket{envoy_cluster_name="my_service"}[5m])
)

# Active connections per cluster
envoy_cluster_upstream_cx_active
```
