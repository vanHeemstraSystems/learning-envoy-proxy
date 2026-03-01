# Story 01-01 — What is Envoy Proxy?

> **Flow:** [Fundamentals](../flows/flow-01-fundamentals.md)  
> **Effort:** ~30 minutes  
> **Next:** [Story 01-02 — Envoy vs NGINX](story-01-02-envoy-vs-nginx.md)

---

## Introduction

Envoy is an open-source, high-performance **L4/L7 proxy and communication bus** designed for large-scale, cloud-native microservice architectures. It was originally built at Lyft to solve the problem of **distributed systems observability and resilience**, and open-sourced in 2016. In 2018, it became a CNCF graduated project.

The core design philosophy: **the network should be transparent to applications**. When failures occur, the source should be easy to determine.

---

## What Problem Does Envoy Solve?

In a monolith, a single process handles all traffic. In a microservices architecture, you have hundreds of services talking to each other over the network. This creates problems:

- **Observability**: Where is the latency? Which service is failing?
- **Reliability**: Retries, circuit breaking, timeouts — who implements them?
- **Security**: mTLS between services — who manages certificates?
- **Traffic management**: Canary deployments, A/B testing — who routes traffic?

The naive answer is "the application developer". Envoy's answer is **"the proxy"** — a sidecar that runs alongside every service and handles all of the above transparently.

---

## Envoy's Architecture at a Glance

```
┌──────────────────────────────────────────────────────┐
│                      Envoy Process                    │
│                                                       │
│   ┌──────────┐    ┌──────────┐    ┌───────────────┐  │
│   │ Listener │───▶│  Filter  │───▶│    Cluster    │  │
│   │ (port)   │    │  Chain   │    │  (upstream)   │  │
│   └──────────┘    └──────────┘    └───────────────┘  │
│                                                       │
│   Admin API (port 9901)                               │
│   Stats / Health / Config dump                        │
└──────────────────────────────────────────────────────┘
```

**Key components:**

| Component | Role |
|---|---|
| **Listener** | Binds to a port and accepts incoming connections |
| **Filter Chain** | Processes connections through a pipeline of filters (L4 or L7) |
| **Router** | Matches requests to routes based on headers, path, etc. |
| **Cluster** | Represents a group of upstream endpoints (backend services) |
| **Endpoint** | An individual upstream instance (IP:port) |
| **Admin API** | HTTP interface for stats, health checks, config dumps |

---

## Envoy's Deployment Models

### 1. Sidecar Proxy (Service Mesh)
Every service pod gets an Envoy sidecar. All inter-service traffic passes through Envoy. This is how Istio works.

```
Pod A                          Pod B
┌───────────────────┐          ┌───────────────────┐
│ App   │   Envoy   │────────▶ │   Envoy  │  App   │
│ :8080 │  sidecar  │          │  sidecar │ :8080  │
└───────────────────┘          └───────────────────┘
```

### 2. Edge Proxy / Ingress
A single Envoy instance sits at the edge of the cluster, handling north-south traffic (external users → cluster). This is how Envoy Gateway works.

### 3. Front Proxy
Envoy sits in front of multiple services, performing routing and load balancing. Common for API gateway use cases.

---

## Key Envoy Features

| Feature | Description |
|---|---|
| **HTTP/2 & gRPC** | First-class support, including transcoding HTTP/1 ↔ gRPC |
| **xDS API** | Dynamic configuration via gRPC — no restarts needed |
| **Observability** | Prometheus metrics, Zipkin/Jaeger tracing, structured logging |
| **Load balancing** | Round-robin, least-request, ring hash, Maglev |
| **Resilience** | Retries, timeouts, circuit breaking, rate limiting |
| **Security** | TLS termination, mTLS, JWT validation, RBAC |
| **Extensibility** | WASM filters, Lua filters, external authorization |

---

## Envoy in the CNCF Landscape

Envoy is used as the data plane in many CNCF projects:

- **Istio** — service mesh (uses Envoy sidecars + istiod as control plane)
- **Envoy Gateway** — Kubernetes Gateway API implementation
- **Contour** — Kubernetes ingress controller (uses Envoy)
- **AWS App Mesh** — AWS's managed service mesh (uses Envoy)
- **Google Cloud Traffic Director** — Google's xDS control plane

---

## Summary

Envoy is a **programmable proxy** — its behavior is defined by configuration, not code. The key insight is that Envoy separates the **data plane** (forwarding packets, applying policies) from the **control plane** (deciding what the configuration should be). This separation is what makes Envoy so powerful in dynamic cloud-native environments.

---

## Knowledge Check

1. What are the four main Envoy building blocks?
2. What port does the Envoy admin API listen on by default?
3. Name two CNCF projects that use Envoy as their data plane.
4. What is the difference between a sidecar deployment and an edge proxy deployment?

---

*Next: [Story 01-02 — Envoy vs NGINX / HAProxy](story-01-02-envoy-vs-nginx.md)*
