# Health Checking

## Active Health Checking

Envoy actively probes upstream endpoints on a configurable interval. If an endpoint fails, Envoy removes it from the load balancer until it recovers.

### HTTP Health Check

```yaml
clusters:
  - name: my_service
    health_checks:
      - timeout: 1s
        interval: 10s
        unhealthy_threshold: 3     # Mark unhealthy after 3 consecutive failures
        healthy_threshold: 2       # Mark healthy again after 2 consecutive successes
        http_health_check:
          path: "/healthz"
          expected_statuses:
            - start: 200
              end: 299
```

### gRPC Health Check

```yaml
health_checks:
  - timeout: 1s
    interval: 10s
    unhealthy_threshold: 3
    healthy_threshold: 2
    grpc_health_check:
      service_name: "my.package.MyService"   # Optional gRPC health check service name
```

### TCP Health Check

Sends a connect + optional payload and expects an optional response:

```yaml
health_checks:
  - timeout: 1s
    interval: 10s
    unhealthy_threshold: 3
    healthy_threshold: 2
    tcp_health_check: {}   # Just checks TCP connection success
```

## Passive Health Checking (Outlier Detection)

Outlier detection monitors response error rates and automatically ejects bad endpoints without a dedicated health check probe:

```yaml
outlier_detection:
  consecutive_5xx: 5
  interval: 10s
  base_ejection_time: 30s
  max_ejection_percent: 50
  success_rate_minimum_hosts: 3
  success_rate_request_volume: 100
  success_rate_stdev_factor: 1900
```

Active and passive health checking complement each other. Use both in production.

## Health Check Event Logging

Enable health check event logs to track endpoint state changes:

```yaml
health_checks:
  - timeout: 1s
    interval: 10s
    unhealthy_threshold: 3
    healthy_threshold: 2
    event_log_path: /dev/stdout   # Log health check events to stdout
    http_health_check:
      path: "/healthz"
```
