# Story 03-03 — Structured Access Logging

> **Flow:** [Observability](../flows/flow-03-observability.md)  
> **Effort:** ~30 minutes

---

## Access Logs in Envoy

Envoy logs every request/response through its access logging system. Unlike application logs, access logs capture the **network-level view**: connection details, upstream response time, bytes transferred, and more.

---

## Log Destinations

| Sink | Description |
|---|---|
| `stdout` | Standard output (default for containers) |
| `stderr` | Standard error |
| `file` | Local file path |
| `gRPC` | Remote log service via gRPC |

---

## Default Access Log Format

Envoy's default log format:

```
[%START_TIME%] "%REQ(:METHOD)% %REQ(X-ENVOY-ORIGINAL-PATH?:PATH)% %PROTOCOL%"
%RESPONSE_CODE% %RESPONSE_FLAGS% %BYTES_RECEIVED% %BYTES_SENT%
%DURATION% %RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)%
"%REQ(X-FORWARDED-FOR)%" "%REQ(USER-AGENT)%" "%REQ(X-REQUEST-ID)%"
"%REQ(:AUTHORITY)%" "%UPSTREAM_HOST%"
```

---

## JSON Structured Access Logging

For log aggregation (ELK, Azure Monitor Logs), JSON format is essential:

```yaml
access_log:
  - name: envoy.access_loggers.stdout
    typed_config:
      "@type": type.googleapis.com/envoy.extensions.access_loggers.stream.v3.StdoutAccessLog
      log_format:
        json_format:
          timestamp: "%START_TIME%"
          method: "%REQ(:METHOD)%"
          path: "%REQ(X-ENVOY-ORIGINAL-PATH?:PATH)%"
          protocol: "%PROTOCOL%"
          response_code: "%RESPONSE_CODE%"
          response_flags: "%RESPONSE_FLAGS%"
          bytes_received: "%BYTES_RECEIVED%"
          bytes_sent: "%BYTES_SENT%"
          duration_ms: "%DURATION%"
          upstream_service_time: "%RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)%"
          x_forwarded_for: "%REQ(X-FORWARDED-FOR)%"
          user_agent: "%REQ(USER-AGENT)%"
          request_id: "%REQ(X-REQUEST-ID)%"
          authority: "%REQ(:AUTHORITY)%"
          upstream_host: "%UPSTREAM_HOST%"
          upstream_cluster: "%UPSTREAM_CLUSTER%"
          trace_id: "%REQ(X-B3-TRACEID)%"
```

---

## Key Command Substitutions

| Command | Description |
|---|---|
| `%START_TIME%` | Request start time (UTC) |
| `%REQ(:METHOD)%` | HTTP method |
| `%REQ(:PATH)%` | Request path |
| `%PROTOCOL%` | Protocol (HTTP/1.1, HTTP/2, HTTP/3) |
| `%RESPONSE_CODE%` | HTTP response code |
| `%RESPONSE_FLAGS%` | Envoy response flags (see below) |
| `%DURATION%` | Total request duration (ms) |
| `%UPSTREAM_HOST%` | Selected upstream host |
| `%UPSTREAM_CLUSTER%` | Selected upstream cluster |
| `%BYTES_RECEIVED%` | Request body bytes |
| `%BYTES_SENT%` | Response body bytes |

---

## Response Flags — Diagnosing Failures

Response flags are Envoy's diagnostic codes. They appear in logs and metrics:

| Flag | Meaning |
|---|---|
| `UH` | No healthy upstream |
| `UF` | Upstream connection failure |
| `UO` | Upstream overflow (circuit breaker) |
| `NR` | No route configured |
| `RL` | Rate limited |
| `UAEX` | Unauthorized (external auth) |
| `DC` | Downstream connection terminated |
| `UC` | Upstream connection terminated |
| `UT` | Upstream request timeout |
| `LH` | Local health check failed |

---

## Filtering Access Logs

Only log errors to reduce volume:

```yaml
access_log:
  - name: envoy.access_loggers.stdout
    filter:
      status_code_filter:
        comparison:
          op: GE
          value:
            default_value: 500
            runtime_key: access_log.min_status_code
    typed_config:
      "@type": type.googleapis.com/envoy.extensions.access_loggers.stream.v3.StdoutAccessLog
```

---

## Summary

JSON structured access logs from Envoy provide rich, machine-readable data per request. Including the `x-request-id` and `x-b3-traceid` correlates logs with distributed traces, enabling end-to-end debugging in the Atlas IDP platform.

---

## Knowledge Check

1. What is the `%RESPONSE_FLAGS%` field and why is it useful?
2. How would you configure Envoy to only log 5xx responses?
3. Which field links access logs to distributed traces?
4. Why is JSON format preferred over text format for access logs in Kubernetes?
