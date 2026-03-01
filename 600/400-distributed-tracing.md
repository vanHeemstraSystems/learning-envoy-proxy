# Distributed Tracing

## Concepts

**Trace** — a record of a request as it flows through multiple services.

**Span** — a single operation within a trace (e.g., "Envoy forwarded request to my-service").

**Trace ID** — a unique ID that correlates all spans belonging to a single end-to-end request.

**Parent Span ID** — the ID of the upstream span that triggered this span.

## How Envoy Participates in Tracing

Envoy creates a **new span** for each request it handles. If the incoming request already carries a trace context (trace ID + parent span ID in HTTP headers), Envoy attaches its span to the existing trace. If not, Envoy starts a new trace.

Envoy then forwards the trace headers downstream, so the receiving application can also create spans that appear as children of Envoy's span.

## Trace Header Propagation

**This is the most important responsibility of the application team.** Envoy creates and forwards trace headers, but the **application** must propagate them in any outgoing requests it makes.

The trace headers Envoy injects (Zipkin B3 format):

```
x-b3-traceid       → 64-bit or 128-bit trace ID (hex)
x-b3-spanid        → 64-bit span ID (hex)
x-b3-parentspanid  → parent span ID (hex)
x-b3-sampled       → 1 = sampled, 0 = not sampled
x-b3-flags         → debug flag
```

For Jaeger (OpenTelemetry-compatible):

```
traceparent: 00-<traceid>-<spanid>-<flags>
tracestate:  vendor-specific
```

## Envoy Tracing Configuration

```yaml
# In the HCM
tracing:
  provider:
    name: envoy.tracers.zipkin
    typed_config:
      "@type": type.googleapis.com/envoy.config.trace.v3.ZipkinConfig
      collector_cluster: zipkin_cluster
      collector_endpoint: "/api/v2/spans"
      collector_endpoint_version: HTTP_JSON
      shared_span_context: false
  random_sampling:
    value: 1.0   # 100% sampling (reduce in production)
```

## Sampling

Sampling at 100% in production is expensive. Use lower rates (e.g., 1%) for high-volume services, but ensure that once a trace is sampled (the `x-b3-sampled: 1` header is set by the first Envoy in the chain), all downstream Envoys and services also sample that trace to preserve the full trace.
