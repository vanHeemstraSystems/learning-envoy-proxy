# Flow 01 — Envoy Fundamentals

## Goal

Build a solid mental model of what Envoy Proxy is, why it exists, and how its core building blocks fit together. After completing this flow you will be able to explain Envoy's architecture to a colleague and run a working proxy locally.

## Why This Matters

Envoy is the de-facto data-plane for cloud-native service meshes (Istio, AWS App Mesh) and API gateways (Envoy Gateway). Understanding Envoy's internals makes you a more effective platform engineer and helps you debug real-world traffic issues in AKS-based environments like Atlas IDP.

## Stories in This Flow

| # | Story | Effort |
|---|---|---|
| 01-01 | [What is Envoy?](../stories/story-01-01-what-is-envoy.md) | 30 min |
| 01-02 | [Envoy vs NGINX / HAProxy](../stories/story-01-02-envoy-vs-nginx.md) | 20 min |
| 01-03 | [Listeners, Clusters, Routes, Endpoints](../stories/story-01-03-listener-cluster-route.md) | 45 min |

## Tasks in This Flow

| # | Task | Effort |
|---|---|---|
| 01-01 | [Install Envoy](../tasks/task-01-01-install-envoy.md) | 15 min |
| 01-02 | [First Proxy](../tasks/task-01-02-first-proxy.md) | 30 min |

## Learning Outcomes

By the end of this flow you will be able to:

- Describe Envoy's role as an L4/L7 proxy and its position in a cloud-native stack
- Contrast Envoy with NGINX and explain when you would choose each
- Draw an Envoy configuration model with Listeners → Routes → Clusters → Endpoints
- Run a working Envoy container that forwards traffic to a backend service
- Access and interpret the Envoy admin API at port 9901

## Estimated Total Time

~2 hours (reading + hands-on)

---

*Next: [Flow 02 — Configuration](flow-02-configuration.md)*
