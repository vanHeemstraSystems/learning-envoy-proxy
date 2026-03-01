# Clusters

## What Is a Cluster?

A cluster is Envoy's representation of an upstream service — a named group of endpoints that Envoy can forward requests to. Envoy maintains connection pools to each endpoint in a cluster.

## Cluster Discovery Types

**`STATIC`** — Endpoints are listed in the config file and do not change.

**`STRICT_DNS`** — Envoy resolves the DNS name on a timer and updates its endpoint list from A/AAAA records. Good for Kubernetes Services backed by headless DNS.

**`LOGICAL_DNS`** — Resolves DNS but only connects to one IP at a time (suitable for single-instance upstreams).

**`EDS`** — Endpoints are provided dynamically by an xDS management server (the most powerful option for Kubernetes).

**`ORIGINAL_DST`** — Used in transparent proxy/sidecar mode; forwards to the original destination extracted from socket metadata.

## Cluster Configuration

```yaml
clusters:
  - name: my_backend
    connect_timeout: 0.25s
    type: STRICT_DNS
    dns_lookup_family: V4_ONLY
    lb_policy: LEAST_REQUEST
    http2_protocol_options: {}  # Enable HTTP/2 to upstream
    health_checks:
      - timeout: 1s
        interval: 10s
        unhealthy_threshold: 3
        healthy_threshold: 2
        http_health_check:
          path: "/healthz"
    circuit_breakers:
      thresholds:
        - priority: DEFAULT
          max_connections: 1000
          max_pending_requests: 1000
          max_requests: 1000
          max_retries: 3
    load_assignment:
      cluster_name: my_backend
      endpoints:
        - lb_endpoints:
            - endpoint:
                address:
                  socket_address:
                    address: my-backend.default.svc.cluster.local
                    port_value: 8080
```

## Load Balancing Policies

| Policy | When to Use |
|---|---|
| `ROUND_ROBIN` | Uniform stateless requests (default) |
| `LEAST_REQUEST` | Varying request durations; gRPC streaming |
| `RANDOM` | Simple and often effective |
| `RING_HASH` | Session affinity via consistent hashing |
| `MAGLEV` | Google's consistent hash; minimal disruption on endpoint changes |

## TLS to Upstream

To encrypt traffic between Envoy and upstream services (e.g., HTTPS backends):

```yaml
transport_socket:
  name: envoy.transport_sockets.tls
  typed_config:
    "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.UpstreamTlsContext
    sni: my-backend.example.com
```
