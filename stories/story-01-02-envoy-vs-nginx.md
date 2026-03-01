# Story 01-02 — Envoy vs NGINX / HAProxy

> **Flow:** [Fundamentals](../flows/flow-01-fundamentals.md)  
> **Effort:** ~20 minutes  
> **Previous:** [Story 01-01 — What is Envoy?](story-01-01-what-is-envoy.md)  
> **Next:** [Story 01-03 — Listeners, Clusters, Routes](story-01-03-listener-cluster-route.md)

---

## Why Compare?

NGINX and HAProxy have been the industry standards for decades. Understanding how Envoy differs — and where it excels — helps you make architectural decisions for the Atlas IDP platform and justify tool choices to stakeholders.

---

## Feature Comparison

| Feature | Envoy | NGINX | HAProxy |
|---|---|---|---|
| **Primary use case** | Service mesh, cloud-native proxy | Web server, reverse proxy | TCP/HTTP load balancer |
| **Protocol support** | HTTP/1, HTTP/2, HTTP/3, gRPC, TCP | HTTP/1, HTTP/2, limited gRPC | HTTP/1, HTTP/2, TCP |
| **Dynamic config** | Yes — xDS API (no restart) | Partial (NGINX Plus) / reload | Runtime API (no restart) |
| **Observability** | Built-in: Prometheus, tracing, logs | Basic stats (NGINX Plus for more) | Built-in stats page |
| **Service discovery** | Yes — EDS via xDS | No (static upstream lists) | No (static server blocks) |
| **Extensibility** | WASM, Lua, external authz | Lua, C modules, OpenResty | Lua, SPOE |
| **Health checking** | Active + passive | Passive only (NGINX Plus: active) | Active + passive |
| **Circuit breaking** | Built-in | Not built-in | Not built-in |
| **Retry logic** | Built-in with budgets | Not built-in | Not built-in |
| **Control plane** | External (Istio, Contour, etc.) | Self-contained | Self-contained |
| **Configuration format** | YAML / JSON (or xDS API) | Custom `nginx.conf` | Custom `haproxy.cfg` |
| **Reload without downtime** | Yes (xDS) | Reload (brief interruption possible) | Runtime API |
| **Resource usage** | Higher (feature-rich) | Low | Low |
| **Learning curve** | Steep | Moderate | Moderate |
| **Community/CNCF** | CNCF graduated | Commercial (F5) | Open source |

---

## When to Choose Envoy

Use Envoy when you need:

- **Dynamic configuration** without restarts — essential in Kubernetes where endpoints change constantly
- **Built-in service discovery** — integrates natively with Kubernetes and cloud provider SDKs
- **Rich observability** — Prometheus metrics and distributed tracing out of the box
- **Service mesh data plane** — if you're evaluating Istio or building a custom mesh
- **Kubernetes Gateway API** — Envoy Gateway is the leading implementation
- **gRPC traffic management** — Envoy has first-class gRPC support including protocol transcoding
- **Advanced traffic policies** — retries, circuit breaking, fault injection for chaos engineering

---

## When to Choose NGINX

Use NGINX when you need:

- **Static web serving** — Envoy is not a web server
- **Simple reverse proxy** with minimal operational complexity
- **Low resource footprint** in constrained environments
- **Team familiarity** — `nginx.conf` is widely understood

---

## When to Choose HAProxy

Use HAProxy when you need:

- **Pure TCP load balancing** with maximum performance
- **Database load balancing** (MySQL, PostgreSQL)
- **Simple, battle-tested HTTP load balancing** without service mesh complexity
- **Very low memory usage** in high-connection-count scenarios

---

## The Atlas IDP Context

For the Atlas IDP platform on AKS:

- **Envoy Gateway** is the right choice for ingress — it implements the Kubernetes Gateway API natively
- **Envoy sidecar** is used if/when you add Istio service mesh capabilities
- **NGINX** may still appear for legacy application workloads or static content
- **HAProxy** may appear in database tier load balancing

Understanding all three tools makes you a more versatile cloud engineer.

---

## Summary

Envoy's superpower is **dynamic configuration and deep observability** at the cost of higher complexity and resource usage. For cloud-native, Kubernetes-first environments — especially when building a platform like Atlas IDP — Envoy is the right tool. For simpler, static workloads, NGINX or HAProxy may still be the pragmatic choice.

---

## Knowledge Check

1. What is the main architectural difference between Envoy and NGINX regarding configuration updates?
2. Why does Envoy require an external control plane while NGINX does not?
3. In which scenario would you prefer HAProxy over Envoy?
4. What CNCF project implements the Kubernetes Gateway API using Envoy?

---

*Next: [Story 01-03 — Listeners, Clusters, Routes, Endpoints](story-01-03-listener-cluster-route.md)*
