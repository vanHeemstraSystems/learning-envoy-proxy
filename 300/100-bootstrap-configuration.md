# Bootstrap Configuration

## What Is the Bootstrap?

The **bootstrap configuration** is the initial configuration file Envoy reads at startup (passed via `envoy -c envoy.yaml`). It defines the static resources Envoy knows about from the start, and optionally points to a management server for dynamic xDS updates.

## Top-Level Structure

```yaml
# envoy.yaml - Minimal bootstrap
admin:
  address:
    socket_address:
      address: 0.0.0.0
      port_value: 9901

static_resources:
  listeners:
    - name: listener_0
      # ... listener definition
  clusters:
    - name: my_service
      # ... cluster definition
```

## Key Top-Level Fields

**`node`** — Identifies this Envoy instance to a management server (required for xDS).

```yaml
node:
  id: envoy-01
  cluster: my-platform
```

**`admin`** — Exposes Envoy's admin HTTP endpoint. Use it to inspect configuration (`/config_dump`), drain connections (`/drain_listeners`), check health (`/healthz/ready`), and view metrics (`/stats/prometheus`).

**`static_resources`** — Contains `listeners`, `clusters`, and `secrets` defined at startup. These are known immediately without a management server.

**`dynamic_resources`** — Points to an xDS management server (covered in section 400).

**`layered_runtime`** — Allows runtime feature flags and overrides (e.g., circuit breaker thresholds).

## Admin Endpoint Security Note

The admin endpoint should **never be exposed publicly**. In Kubernetes, bind it to `127.0.0.1` or use a network policy to restrict access.

```yaml
admin:
  address:
    socket_address:
      address: 127.0.0.1  # Loopback only
      port_value: 9901
```

## Full Minimal Example

```yaml
node:
  id: proxy-01
  cluster: local

admin:
  access_log_path: /dev/null
  address:
    socket_address:
      address: 127.0.0.1
      port_value: 9901

static_resources:
  listeners:
    - name: listener_0
      address:
        socket_address:
          address: 0.0.0.0
          port_value: 10000
      filter_chains:
        - filters:
            - name: envoy.filters.network.http_connection_manager
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
                stat_prefix: ingress_http
                route_config:
                  name: local_route
                  virtual_hosts:
                    - name: backend
                      domains: ["*"]
                      routes:
                        - match:
                            prefix: "/"
                          route:
                            cluster: my_service
                http_filters:
                  - name: envoy.filters.http.router
                    typed_config:
                      "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router

  clusters:
    - name: my_service
      connect_timeout: 0.25s
      type: STATIC
      load_assignment:
        cluster_name: my_service
        endpoints:
          - lb_endpoints:
              - endpoint:
                  address:
                    socket_address:
                      address: 127.0.0.1
                      port_value: 8080
```
