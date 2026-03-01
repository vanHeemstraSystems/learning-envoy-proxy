# Listeners, Filters, and Clusters

## The Three Core Concepts

Every Envoy configuration revolves around three entities: **Listeners**, **Filters**, and **Clusters**.

## Listeners

A **Listener** defines where Envoy accepts incoming connections — a combination of IP address and port.

```yaml
listeners:
  - name: listener_0
    address:
      socket_address:
        address: 0.0.0.0
        port_value: 10000
```

Envoy can have multiple listeners simultaneously (e.g., port 80 for HTTP, port 443 for HTTPS, port 9901 for the admin panel).

## Filters

Filters are the processing logic attached to a listener. They are organized into a **filter chain**. There are two levels:

**Network (L3/L4) Filters** — operate on raw bytes/TCP connections. The most important one is the **HTTP Connection Manager (HCM)**, which upgrades a TCP connection to an HTTP-aware proxy.

**HTTP Filters** — operate on HTTP requests and responses within the HCM. These are chained and run in order for every request passing through the listener.

Common HTTP filters:

| Filter | Purpose |
|---|---|
| `envoy.filters.http.router` | Required final filter; forwards to a cluster |
| `envoy.filters.http.jwt_authn` | Validates JWTs |
| `envoy.filters.http.rbac` | Enforces RBAC policies |
| `envoy.filters.http.ratelimit` | Enforces rate limits |
| `envoy.filters.http.lua` | Runs Lua scripts |

## Clusters

A **Cluster** is a group of upstream hosts (endpoints) that Envoy can forward traffic to.

```yaml
clusters:
  - name: my_service
    connect_timeout: 0.25s
    type: STRICT_DNS
    lb_policy: ROUND_ROBIN
    load_assignment:
      cluster_name: my_service
      endpoints:
        - lb_endpoints:
            - endpoint:
                address:
                  socket_address:
                    address: my-service.default.svc.cluster.local
                    port_value: 8080
```

## The Flow

```
Client → [Listener: port 10000]
            → [Network Filter: HTTP Connection Manager]
                → [HTTP Filter: jwt_authn]
                → [HTTP Filter: ratelimit]
                → [HTTP Filter: router]
                    → [Cluster: my_service]
                        → [Endpoint: 10.0.0.1:8080]
                        → [Endpoint: 10.0.0.2:8080]
```
