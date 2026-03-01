# Circuit Breakers

## What Are Circuit Breakers?

Circuit breakers prevent a single struggling upstream service from overwhelming Envoy's resources (and cascading to other services). They place limits on the number of concurrent connections and pending requests per cluster.

Unlike a traditional circuit breaker pattern that has open/closed/half-open states, Envoy's circuit breakers are **threshold-based** — they reject requests immediately when a threshold is exceeded without going through state transitions.

## Configuration

```yaml
clusters:
  - name: my_service
    circuit_breakers:
      thresholds:
        - priority: DEFAULT
          max_connections: 1000        # Max concurrent TCP connections to all endpoints
          max_pending_requests: 1000   # Max requests queued waiting for a connection
          max_requests: 1000           # Max concurrent HTTP requests in flight
          max_retries: 3               # Max concurrent retries
          track_remaining: true        # Expose remaining capacity in stats

        - priority: HIGH               # HIGH priority traffic (set per-route with x-envoy-upstream-rq-timeout-ms)
          max_connections: 2000
          max_requests: 2000
```

## What Happens When a Threshold Is Exceeded?

- For `max_connections`: New connections are rejected with a `503` response. Envoy records a `cx_overflow` stat.
- For `max_pending_requests`: Pending requests are rejected with `503`. Envoy records a `rq_pending_overflow` stat.
- For `max_requests`: Active requests are rejected with `503`. Envoy records a `rq_overflow` stat.

## Monitoring Circuit Breaker Stats

Key metrics to watch (available at `GET /stats`):

```
cluster.my_service.upstream_cx_overflow
cluster.my_service.upstream_rq_pending_overflow
cluster.my_service.upstream_rq_overflow
cluster.my_service.circuit_breakers.default.cx_open
cluster.my_service.circuit_breakers.default.rq_open
```

## Outlier Detection (Passive Circuit Breaking)

Complementary to threshold-based circuit breakers, **outlier detection** automatically ejects misbehaving endpoints:

```yaml
outlier_detection:
  consecutive_5xx: 5              # Eject after 5 consecutive 5xx responses
  consecutive_gateway_failure: 5  # Eject after 5 consecutive gateway errors
  interval: 10s
  base_ejection_time: 30s         # How long to keep endpoint ejected (doubles each time)
  max_ejection_percent: 50        # Cap the % of ejected endpoints to preserve availability
  success_rate_minimum_hosts: 5   # Only apply rate-based ejection if ≥5 hosts
```
