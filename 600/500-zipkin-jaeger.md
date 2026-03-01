# Zipkin and Jaeger Integration

## Zipkin

Zipkin uses the B3 propagation format. Configure Envoy to send spans to a Zipkin-compatible collector:

```yaml
# HCM tracing section
tracing:
  provider:
    name: envoy.tracers.zipkin
    typed_config:
      "@type": type.googleapis.com/envoy.config.trace.v3.ZipkinConfig
      collector_cluster: zipkin
      collector_endpoint: "/api/v2/spans"
      collector_endpoint_version: HTTP_JSON
      collector_hostname: zipkin.monitoring.svc.cluster.local
      shared_span_context: false
  random_sampling:
    value: 1.0   # 100% (reduce in production)
```

```yaml
clusters:
  - name: zipkin
    connect_timeout: 1s
    type: STRICT_DNS
    load_assignment:
      cluster_name: zipkin
      endpoints:
        - lb_endpoints:
            - endpoint:
                address:
                  socket_address:
                    address: zipkin.monitoring.svc.cluster.local
                    port_value: 9411
```

## Jaeger (via Zipkin-compatible endpoint)

Jaeger exposes a Zipkin-compatible HTTP collector endpoint. Point Envoy's Zipkin tracer at Jaeger's collector:

```yaml
tracing:
  provider:
    name: envoy.tracers.zipkin
    typed_config:
      "@type": type.googleapis.com/envoy.config.trace.v3.ZipkinConfig
      collector_cluster: jaeger
      collector_endpoint: "/api/v2/spans"   # Jaeger's Zipkin-compatible endpoint
      collector_endpoint_version: HTTP_JSON
      shared_span_context: false
```

## OpenTelemetry (Recommended for New Deployments)

For new deployments, prefer the OpenTelemetry tracer which supports the W3C Trace Context standard (`traceparent` header):

```yaml
tracing:
  provider:
    name: envoy.tracers.opentelemetry
    typed_config:
      "@type": type.googleapis.com/envoy.config.trace.v3.OpenTelemetryConfig
      grpc_service:
        envoy_grpc:
          cluster_name: otel_collector
        timeout: 0.5s
      service_name: "my-envoy-proxy"
```

## What Envoy Adds to Each Span

- Operation name (route name or cluster name)
- Request start time and duration
- HTTP method, URL, and status code
- Downstream and upstream remote addresses
- Custom tags from request headers (configurable via `custom_tags`)
