# Performance Tuning

## Concurrency

Set the number of worker threads to match available CPU cores. By default, Envoy uses all available cores.

```bash
# CLI flag
envoy --concurrency 4 -c envoy.yaml

# Or let it auto-detect (default):
envoy -c envoy.yaml
```

In Kubernetes, set CPU limits carefully. A pod with a 2-core CPU limit should set `--concurrency 2`. Mismatches (e.g., 8 workers on a 2-core pod) cause excessive context switching.

## Buffer Sizes

For high-throughput proxies handling large request/response bodies, tune buffer sizes:

```yaml
# Per-listener connection buffer limit
listeners:
  - name: listener_0
    per_connection_buffer_limit_bytes: 1048576   # 1MB per connection

# Per-cluster upstream buffer limit
clusters:
  - name: my_service
    per_connection_buffer_limit_bytes: 1048576
```

The HCM has its own body buffer settings:

```yaml
http_connection_manager:
  stream_idle_timeout: 300s
  request_timeout: 300s
  max_request_headers_kb: 60    # Default 60KB; increase for large JWT tokens
```

## Connection Keep-Alive

Reusing upstream connections is critical for performance. Configure connection pool keep-alive settings:

```yaml
clusters:
  - name: my_service
    typed_extension_protocol_options:
      envoy.extensions.upstreams.http.v3.HttpProtocolOptions:
        "@type": type.googleapis.com/envoy.extensions.upstreams.http.v3.HttpProtocolOptions
        upstream_http_protocol_options:
          auto_sni: true
          auto_san_validation: true
        common_http_protocol_options:
          max_requests_per_connection: 0          # 0 = unlimited (reuse indefinitely)
          idle_timeout: 3600s                     # Keep idle connections alive for 1 hour
          http2_protocol_options:
            max_concurrent_streams: 100           # Max concurrent HTTP/2 streams per connection
            initial_stream_window_size: 65536
            initial_connection_window_size: 1048576
```

## Access Log Performance

High-volume access logging adds latency. For performance-critical deployments:

- Use conditional access logging (log only errors)
- Use the file access logger with buffered writes rather than stdout
- Reduce log fields to only what is needed

## Prometheus Metrics Cardinality

By default, Envoy emits per-route and per-cluster metrics. In large clusters with hundreds of services, this creates high cardinality. Use `stats_matcher` to limit emitted metrics:

```yaml
stats_config:
  stats_matcher:
    inclusion_list:
      patterns:
        - safe_regex:
            regex: "cluster\\..*\\.(upstream_rq|upstream_cx|circuit_breakers).*"
        - safe_regex:
            regex: "http\\..*\\.(downstream_rq|downstream_cx).*"
        - exact: "server.live"
```
