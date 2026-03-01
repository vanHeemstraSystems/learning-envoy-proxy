# Troubleshooting Envoy

## Admin API — Your First Stop

Envoy's admin API (default port 9901) is the primary troubleshooting tool.

**View the complete active configuration:**
```bash
curl http://localhost:9901/config_dump | jq .
```

**Check listener status:**
```bash
curl http://localhost:9901/listeners
```

**Check cluster health and stats:**
```bash
curl http://localhost:9901/clusters
```

**View all statistics:**
```bash
curl http://localhost:9901/stats
# Filter for a specific cluster:
curl "http://localhost:9901/stats?filter=cluster.my_service"
```

**Prometheus-format metrics:**
```bash
curl http://localhost:9901/stats/prometheus
```

**Check Envoy readiness (returns 200 if ready, 503 if not):**
```bash
curl http://localhost:9901/ready
```

## Common Issues and Solutions

### 503 Service Unavailable — No Healthy Upstreams

```bash
# Check if endpoints are healthy
curl http://localhost:9901/clusters | grep my_service

# Look for:
# my_service::10.0.0.1:8080::health_flags::healthy
# or
# my_service::10.0.0.1:8080::health_flags::failed_eds_health
```

**Causes**: All endpoints marked unhealthy by active health checks, outlier detection ejected all endpoints, EDS sent empty endpoint list, DNS resolution failure for STRICT_DNS cluster.

### 503 — Circuit Breaker Open

```bash
curl "http://localhost:9901/stats?filter=overflow"
```

If `upstream_rq_pending_overflow` or `upstream_cx_overflow` is incrementing, the circuit breaker threshold is being hit. Increase the threshold or reduce load.

### Connection Refused to Upstream

```bash
# Check if upstream address is resolving
curl "http://localhost:9901/clusters?format=json" | jq '.cluster_statuses[] | select(.name=="my_service")'
```

Verify the upstream host and port in the cluster config. For STRICT_DNS, check DNS resolution from within the Envoy container.

### 431 Request Header Fields Too Large

The HCM has a default `max_request_headers_kb: 60` limit. If clients send large headers (e.g., long JWTs), increase this:

```yaml
http_connection_manager:
  max_request_headers_kb: 96
```

### Slow Requests / High Latency

Check per-cluster latency stats:
```bash
curl "http://localhost:9901/stats?filter=cluster.my_service.upstream_rq_time"
```

Enable access logging with latency fields to identify slow upstreams.

## Increasing Log Verbosity

Change Envoy's log level at runtime (no restart needed):
```bash
# Set all loggers to debug
curl -X POST "http://localhost:9901/logging?level=debug"

# Set a specific component
curl -X POST "http://localhost:9901/logging?http=debug"
curl -X POST "http://localhost:9901/logging?upstream=debug"
curl -X POST "http://localhost:9901/logging?conn_handler=debug"
```

Available levels: `trace`, `debug`, `info`, `warn`, `error`, `critical`, `off`

**Return to info after debugging** — debug logging is extremely verbose and will degrade performance:
```bash
curl -X POST "http://localhost:9901/logging?level=info"
```

## Kubernetes-Specific Debugging

**Check Envoy sidecar logs in a pod:**
```bash
kubectl logs <pod-name> -c istio-proxy --tail=100
```

**Execute admin commands inside the sidecar:**
```bash
kubectl exec <pod-name> -c istio-proxy -- curl -s http://localhost:15000/config_dump | jq .
kubectl exec <pod-name> -c istio-proxy -- curl -s http://localhost:15000/stats | grep overflow
```

**Istio-specific port numbers:**
- `15000` — Envoy admin
- `15001` — Envoy outbound listener (traffic from app to external services)
- `15006` — Envoy inbound listener (traffic from other services to this app)
- `15090` — Prometheus metrics

## Envoy Access Log for Debugging

Enable JSON access logging and look for the `RESPONSE_FLAGS` field, which explains why a request was terminated:

| Flag | Meaning |
|---|---|
| `UH` | No healthy upstream hosts |
| `UF` | Upstream connection failure |
| `UO` | Upstream overflow (circuit breaker) |
| `NR` | No route configured for this request |
| `RL` | Rate limited |
| `UC` | Upstream connection termination |
| `DC` | Downstream connection termination |
