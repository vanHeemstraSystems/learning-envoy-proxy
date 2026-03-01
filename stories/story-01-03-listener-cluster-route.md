# Story 01-03 — Listeners, Clusters, Routes, and Endpoints

> **Flow:** [Fundamentals](../flows/flow-01-fundamentals.md)  
> **Effort:** ~45 minutes  
> **Previous:** [Story 01-02 — Envoy vs NGINX](story-01-02-envoy-vs-nginx.md)  
> **Tasks:** [Task 01-01](../tasks/task-01-01-install-envoy.md) | [Task 01-02](../tasks/task-01-02-first-proxy.md)

---

## The Envoy Configuration Model

Envoy's entire behavior is described by four core concepts. Understanding their relationships is the foundation of everything else.

```
Downstream                                                    Upstream
(Client)                                                      (Backend)
   │
   ▼
┌──────────┐      ┌────────────────────┐      ┌───────────┐     ┌──────────┐
│ Listener │─────▶│  Filter Chain      │─────▶│  Cluster  │────▶│ Endpoint │
│ :10000   │      │  (L4 + L7 filters) │      │  my-svc   │     │ 10.0.0.1 │
└──────────┘      └────────────────────┘      └───────────┘     │ 10.0.0.2 │
                        │                                        └──────────┘
                        ▼
                  ┌───────────┐
                  │   Router  │
                  │ (Virtual  │
                  │  Host /   │
                  │   Route)  │
                  └───────────┘
```

---

## Listener

A **Listener** is a named network location (IP address + port) that Envoy binds to and accepts connections on. There can be multiple listeners, each handling different ports or protocols.

```yaml
listeners:
  - name: listener_0
    address:
      socket_address:
        address: 0.0.0.0
        port_value: 10000
    filter_chains:
      - filters:
          - name: envoy.filters.network.http_connection_manager
            # ... HCM config
```

**Key attributes:**

| Attribute | Description |
|---|---|
| `name` | Unique identifier |
| `address` | Socket to bind to (IP:port) |
| `filter_chains` | Ordered list of filter chains to apply |
| `listener_filters` | Pre-connection processing (e.g., TLS inspector) |

---

## Filter Chain & Filters

A **Filter Chain** is a pipeline of filters applied to each connection. Filters can be:

- **Network (L4) filters** — operate on raw TCP bytes (e.g., `tcp_proxy`, `http_connection_manager`)
- **HTTP (L7) filters** — operate on HTTP requests/responses (e.g., `router`, `jwt_authn`, `cors`)

The most important network filter is the **HTTP Connection Manager (HCM)**, which handles HTTP/1.1 and HTTP/2 and hosts the HTTP filter chain.

```yaml
filter_chains:
  - filters:
      - name: envoy.filters.network.http_connection_manager
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
          stat_prefix: ingress_http
          http_filters:
            - name: envoy.filters.http.router
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router
```

---

## Route Configuration (Virtual Hosts & Routes)

Inside the HCM, a **RouteConfiguration** defines how incoming HTTP requests are matched and forwarded.

```
RouteConfiguration
  └── VirtualHost (matches: Host header domain)
        └── Route (matches: path prefix, method, headers)
              └── RouteAction (forward to cluster, redirect, or direct response)
```

```yaml
route_config:
  name: local_route
  virtual_hosts:
    - name: local_service
      domains: ["*"]       # Match any Host header
      routes:
        - match:
            prefix: "/api"   # Match requests starting with /api
          route:
            cluster: backend_cluster
        - match:
            prefix: "/"
          direct_response:
            status: 404
            body:
              inline_string: "Not found"
```

---

## Cluster

A **Cluster** represents a group of upstream (backend) services. It handles load balancing across multiple endpoints.

```yaml
clusters:
  - name: backend_cluster
    connect_timeout: 5s
    type: STATIC           # or STRICT_DNS, LOGICAL_DNS, EDS
    lb_policy: ROUND_ROBIN
    load_assignment:
      cluster_name: backend_cluster
      endpoints:
        - lb_endpoints:
            - endpoint:
                address:
                  socket_address:
                    address: 127.0.0.1
                    port_value: 8080
```

**Cluster types:**

| Type | Description |
|---|---|
| `STATIC` | Endpoints are hardcoded in config |
| `STRICT_DNS` | DNS resolution; all returned IPs used |
| `LOGICAL_DNS` | DNS resolution; only the first IP used |
| `EDS` | Dynamic endpoints from xDS Endpoint Discovery Service |

**Load balancing policies:**

| Policy | Description |
|---|---|
| `ROUND_ROBIN` | Distribute requests evenly (default) |
| `LEAST_REQUEST` | Prefer endpoints with fewest active requests |
| `RING_HASH` | Consistent hashing; sticky sessions |
| `MAGLEV` | Google Maglev consistent hashing |
| `RANDOM` | Random selection |

---

## Endpoint

An **Endpoint** is an individual upstream instance: an IP address and port. Endpoints live within a Cluster's `load_assignment`.

In dynamic environments (Kubernetes), endpoints are discovered via EDS (Endpoint Discovery Service) and updated without Envoy restart as pods come and go.

---

## Putting It All Together

Here is a complete minimal static configuration:

```yaml
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
                    - name: local_service
                      domains: ["*"]
                      routes:
                        - match:
                            prefix: "/"
                          route:
                            cluster: service_backend
                http_filters:
                  - name: envoy.filters.http.router
                    typed_config:
                      "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router

  clusters:
    - name: service_backend
      connect_timeout: 5s
      type: STATIC
      lb_policy: ROUND_ROBIN
      load_assignment:
        cluster_name: service_backend
        endpoints:
          - lb_endpoints:
              - endpoint:
                  address:
                    socket_address:
                      address: 127.0.0.1
                      port_value: 8080

admin:
  address:
    socket_address:
      address: 0.0.0.0
      port_value: 9901
```

---

## Summary

| Concept | Analogy | Role |
|---|---|---|
| Listener | Front door | Accepts incoming connections |
| Filter Chain | Security checkpoint | Processes & transforms traffic |
| Virtual Host | DNS name | Groups routes by domain |
| Route | Traffic sign | Matches requests and decides destination |
| Cluster | Load balancer pool | Groups backend instances |
| Endpoint | Individual server | Receives forwarded traffic |

---

## Knowledge Check

1. What is the relationship between a Listener and a Filter Chain?
2. What filter is responsible for HTTP routing in Envoy?
3. What cluster type would you use for Kubernetes pod endpoints that change dynamically?
4. Draw the request flow from a client through Envoy to a backend service.

---

*Tasks: [Task 01-01 — Install Envoy](../tasks/task-01-01-install-envoy.md) | [Task 01-02 — First Proxy](../tasks/task-01-02-first-proxy.md)*
