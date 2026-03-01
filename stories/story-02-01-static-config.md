# Story 02-01 — Static Bootstrap Configuration

> **Flow:** [Configuration](../flows/flow-02-configuration.md)  
> **Effort:** ~45 minutes  
> **Next:** [Story 02-02 — xDS API](story-02-02-xds-api.md)  
> **Task:** [Task 02-01 — Write Static Config](../tasks/task-02-01-write-static-config.md)

---

## What is the Bootstrap Configuration?

When Envoy starts, it reads a **bootstrap configuration file** — a YAML or JSON document that defines the initial configuration. This file is the entry point for all Envoy configuration.

The bootstrap configuration can be either:
- **Fully static** — all listeners, clusters, and routes are defined in the file; no runtime updates
- **Hybrid** — some resources are static, others are loaded dynamically via xDS APIs

---

## Bootstrap File Structure

```yaml
# Top-level bootstrap structure
node:                        # Envoy's identity (used by control planes)
  id: my-proxy
  cluster: my-cluster

static_resources:            # Static listeners and clusters
  listeners: [...]
  clusters: [...]

dynamic_resources:           # xDS API endpoints (optional)
  ads_config: ...
  lds_config: ...
  cds_config: ...

admin:                       # Admin API configuration
  address:
    socket_address:
      address: 0.0.0.0
      port_value: 9901

layered_runtime:             # Runtime flags and overrides (optional)
  layers: [...]

stats_sinks:                 # Metrics export (optional)
  - name: envoy.stat_sinks.statsd
    ...
```

---

## The `node` Block

The `node` block defines Envoy's identity. This is important when using a control plane — it tells the control plane which proxy is connecting and allows the control plane to send targeted configuration.

```yaml
node:
  id: envoy-proxy-1          # Unique instance identifier
  cluster: edge-proxy        # Logical group this proxy belongs to
  metadata:
    environment: production
    region: westeurope
```

---

## The `admin` Block

The admin API is your operational window into Envoy. Always configure it.

```yaml
admin:
  address:
    socket_address:
      address: 127.0.0.1    # Bind to localhost only in production!
      port_value: 9901
  access_log:
    - name: envoy.access_loggers.stdout
      typed_config:
        "@type": type.googleapis.com/envoy.extensions.access_loggers.stream.v3.StdoutAccessLog
```

**Useful admin endpoints:**

| Endpoint | Description |
|---|---|
| `GET /stats/prometheus` | Prometheus-format metrics |
| `GET /config_dump` | Complete running configuration |
| `GET /clusters` | Cluster health and stats |
| `GET /listeners` | Active listeners |
| `POST /healthcheck/fail` | Mark this instance unhealthy |
| `GET /ready` | Readiness check (returns 200 when live) |
| `POST /logging?level=debug` | Change log level at runtime |

---

## Static Listeners in Depth

A complete listener configuration with TLS inspection and routing:

```yaml
listeners:
  - name: https_listener
    address:
      socket_address:
        address: 0.0.0.0
        port_value: 443
    listener_filters:
      - name: envoy.filters.listener.tls_inspector  # Detect TLS before filter chain
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.listener.tls_inspector.v3.TlsInspector
    filter_chains:
      - filter_chain_match:
          server_names: ["api.example.com"]     # SNI-based routing
        transport_socket:
          name: envoy.transport_sockets.tls
          typed_config:
            "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.DownstreamTlsContext
            common_tls_context:
              tls_certificates:
                - certificate_chain:
                    filename: /etc/certs/server.crt
                  private_key:
                    filename: /etc/certs/server.key
        filters:
          - name: envoy.filters.network.http_connection_manager
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
              stat_prefix: ingress_https
              route_config:
                virtual_hosts:
                  - name: api
                    domains: ["api.example.com"]
                    routes:
                      - match: { prefix: "/" }
                        route: { cluster: api_cluster }
              http_filters:
                - name: envoy.filters.http.router
                  typed_config:
                    "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router
```

---

## Static Clusters in Depth

```yaml
clusters:
  - name: api_cluster
    connect_timeout: 10s
    type: STRICT_DNS         # Resolve DNS and use all returned IPs
    lb_policy: LEAST_REQUEST
    respect_dns_ttl: true
    dns_refresh_rate: 5s
    load_assignment:
      cluster_name: api_cluster
      endpoints:
        - lb_endpoints:
            - endpoint:
                address:
                  socket_address:
                    address: api-service.default.svc.cluster.local
                    port_value: 8080
    health_checks:
      - timeout: 2s
        interval: 10s
        unhealthy_threshold: 3
        healthy_threshold: 2
        http_health_check:
          path: "/health"
    circuit_breakers:
      thresholds:
        - priority: DEFAULT
          max_connections: 1024
          max_pending_requests: 1024
          max_requests: 1024
          max_retries: 3
    upstream_connection_options:
      tcp_keepalive:
        keepalive_probes: 3
        keepalive_time: 30
        keepalive_interval: 5
```

---

## Layered Runtime

Runtime flags let you control Envoy's behavior without config changes:

```yaml
layered_runtime:
  layers:
    - name: static_layer
      static_layer:
        upstream.healthy_panic_threshold: 50   # % of healthy endpoints below which panic mode activates
        envoy.deprecated_features:allow_all: true
    - name: admin_layer
      admin_layer: {}    # Allow runtime changes via admin API POST /runtime_modify
```

---

## Common Mistakes

| Mistake | Fix |
|---|---|
| Admin bound to `0.0.0.0` in production | Bind to `127.0.0.1` or use network policies |
| No health checks on clusters | Always add `health_checks` |
| No circuit breakers | Always set `circuit_breakers.thresholds` |
| No `connect_timeout` | Set reasonable timeouts (5–30s) |
| Missing `stat_prefix` | Required on HCM; used for metric labels |

---

## Summary

The bootstrap file is Envoy's source of truth at startup. A well-structured bootstrap file includes a `node` identity block, clearly scoped `admin` API, carefully tuned `clusters` with health checks and circuit breakers, and typed `listeners` with explicit filter chains.

---

## Knowledge Check

1. What is the purpose of the `node` block in the bootstrap configuration?
2. Which admin endpoint returns Prometheus-format metrics?
3. What does `STRICT_DNS` cluster type do differently from `STATIC`?
4. What is a layered runtime and why is it useful?

---

*Task: [Task 02-01 — Write Static Config](../tasks/task-02-01-write-static-config.md)*  
*Next: [Story 02-02 — xDS Dynamic Configuration API](story-02-02-xds-api.md)*
