# xDS API Overview

## The Problem with Static Configuration

In a Kubernetes cluster, pods are ephemeral. Their IP addresses change when they restart. New pods are added and removed continuously as deployments scale. A static Envoy configuration file cannot keep up with this dynamism.

## What Is xDS?

**xDS** (x Discovery Service) is a family of gRPC-based APIs through which a **control plane** pushes configuration resources to Envoy (the **data plane**) without any restarts. Envoy subscribes to resources and the control plane streams updates.

"x" is a placeholder — the family includes:

| Acronym | Full Name | Manages |
|---|---|---|
| LDS | Listener Discovery Service | Listeners |
| RDS | Route Discovery Service | Route configurations |
| CDS | Cluster Discovery Service | Clusters |
| EDS | Endpoint Discovery Service | Endpoints within clusters |
| SDS | Secret Discovery Service | TLS certificates and keys |
| ADS | Aggregated Discovery Service | All of the above on one stream |
| RTDS | Runtime Discovery Service | Runtime feature flags |

## Control Plane vs Data Plane

**Data plane** = Envoy. It handles actual traffic.

**Control plane** = the system that pushes xDS resources to Envoy. Examples:
- **Istio Pilot (istiod)** — translates Kubernetes Service/VirtualService resources to xDS
- **Contour** — translates Kubernetes Ingress/HTTPProxy to xDS
- **Custom control plane** — you build one using the Go/Java/Python xDS server SDKs

## Push vs Pull

Envoy **subscribes** to resource types and the control plane **pushes** updates. This is a server-streaming gRPC model. Envoy tells the control plane what it already has (via a version nonce), and the control plane sends only what has changed.

## Versioning (v3 API)

Always use the **v3 xDS API**. The v2 API is deprecated and removed. The key difference is the `@type` URL prefix:
- v3: `type.googleapis.com/envoy.config.listener.v3.Listener`
- v2 (deprecated): `type.googleapis.com/envoy.api.v2.Listener`
