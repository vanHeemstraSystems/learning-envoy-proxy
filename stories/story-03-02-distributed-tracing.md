# Story 03-02 — Distributed Tracing with Jaeger / Zipkin

> **Flow:** [Observability](../flows/flow-03-observability.md)  
> **Effort:** ~45 minutes  
> **Task:** [Task 03-02 — Jaeger Tracing](../tasks/task-03-02-jaeger-tracing.md)

---

## What is Distributed Tracing?

In a microservices architecture, a single user request may traverse dozens of services. Distributed tracing captures the full request journey as a **trace** composed of **spans**, each representing one service call.

Envoy automatically creates spans for every HTTP request it proxies — you get tracing without modifying application code.

---

## Trace Concepts

| Concept | Description |
|---|---|
| **Trace** | The complete journey of one request (collection of spans) |
| **Span** | A single operation within a trace (start time, duration, metadata) |
| **Trace ID** | Unique identifier shared across all spans of a trace |
| **Span ID** | Unique identifier for a single span |
| **Parent Span ID** | Links a child span to its parent |
| **Baggage** | Key-value pairs propagated across services |

---

## Tracing Providers

Envoy supports multiple tracing backends:

| Provider | Type | Cloud Option |
|---|---|---|
| **Jaeger** | Open source | Self-hosted / Jaeger Operator |
| **Zipkin** | Open source | Self-hosted |
| **Tempo** | Open source (Grafana) | Grafana Cloud |
| **AWS X-Ray** | Commercial | AWS native |
| **Datadog** | Commercial | SaaS |
| **OpenTelemetry** | Standard | Any OTLP-compatible backend |

For Atlas IDP, **Jaeger** or **Tempo via OpenTelemetry** are recommended.

---

## Envoy Tracing Configuration

```yaml
static_resources:
  clusters:
    - name: jaeger_cluster
      type: STRICT_DNS
      connect_timeout: 5s
      load_assignment:
        cluster_name: jaeger_cluster
        endpoints:
          - lb_endpoints:
              - endpoint:
                  address:
                    socket_address:
                      address: jaeger-collector.monitoring.svc.cluster.local
                      port_value: 9411   # Zipkin-compatible endpoint

# In HCM filter config:
# tracing:
#   provider:
#     name: envoy.tracers.zipkin
#     typed_config:
#       "@type": type.googleapis.com/envoy.config.trace.v3.ZipkinConfig
#       collector_cluster: jaeger_cluster
#       collector_endpoint: "/api/v2/spans"
#       collector_endpoint_version: HTTP_JSON
#       trace_id_128bit: true
#       shared_span_context: false
```

---

## Trace Header Propagation

Envoy propagates trace context using the **B3** or **W3C TraceContext** headers:

| Header | Purpose |
|---|---|
| `x-b3-traceid` | Trace identifier (64 or 128 bit hex) |
| `x-b3-spanid` | Current span identifier |
| `x-b3-parentspanid` | Parent span identifier |
| `x-b3-sampled` | Whether this trace is sampled (0 or 1) |
| `x-request-id` | Envoy's unique request ID (also logged) |

**Important:** Envoy propagates headers automatically to the first upstream hop. Your **application services** must forward these headers when making downstream calls, or the trace will be broken.

---

## Sampling Configuration

```yaml
tracing:
  provider:
    name: envoy.tracers.zipkin
    typed_config:
      "@type": type.googleapis.com/envoy.config.trace.v3.ZipkinConfig
      # ... collector config

# In HCM:
# tracing:
#   random_sampling:
#     value: 10.0   # Sample 10% of requests
#   overall_sampling:
#     value: 100.0
```

---

## Summary

Envoy's built-in tracing generates spans for every proxied request. Combined with Jaeger, you get a complete picture of request latency across all services — invaluable for diagnosing performance issues in the Atlas IDP platform.

---

## Knowledge Check

1. What is the difference between a trace and a span?
2. Which trace context headers does Envoy propagate by default?
3. Why must application services forward trace headers?
4. What sampling rate would you use in production and why?
