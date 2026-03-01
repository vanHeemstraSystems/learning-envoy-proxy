# Story 02-03 — Control Planes: go-control-plane and Contour

> **Flow:** [Configuration](../flows/flow-02-configuration.md)  
> **Effort:** ~45 minutes  
> **Previous:** [Story 02-02 — xDS API](story-02-02-xds-api.md)

---

## What is a Control Plane?

A **control plane** is the component responsible for:
1. Watching the desired state (Kubernetes resources, service registry, config files)
2. Computing the corresponding xDS configuration
3. Pushing that configuration to Envoy instances via the xDS API

Envoy itself is the **data plane** — it only forwards traffic. The control plane makes decisions.

```
Desired State              Control Plane              Data Plane
(Kubernetes CRDs,   ──▶   (translates intent   ──▶   (Envoy — forwards
 Consul catalog,           to xDS resources)           traffic)
 config files)
```

---

## go-control-plane

[go-control-plane](https://github.com/envoyproxy/go-control-plane) is the official Go library for building xDS-compatible control planes. It is used as the foundation for many production control planes including Istio's `istiod`, Contour, and Envoy Gateway.

**Key capabilities:**
- Complete xDS v3 server implementation in Go
- Linear cache (SotW) and delta cache implementations
- Snapshot-based configuration management
- Request/ACK/NACK handling built in

**Snapshot model:**

```go
snapshot, _ := cache.NewSnapshot("version-1",
    map[resource.Type][]types.Resource{
        resource.ClusterType:  []types.Resource{cluster},
        resource.ListenerType: []types.Resource{listener},
        resource.RouteType:    []types.Resource{route},
        resource.EndpointType: []types.Resource{endpoint},
    },
)
snapshotCache.SetSnapshot(ctx, nodeID, snapshot)
```

---

## Contour

[Contour](https://projectcontour.io) is a Kubernetes ingress controller built on Envoy. It was one of the first production-grade open-source control planes.

**Architecture:**
```
Kubernetes API
      │
      ▼
  Contour (control plane)
      │ xDS (via gRPC)
      ▼
   Envoy (data plane)
      │
      ▼
   Traffic
```

Contour supports both the legacy `Ingress` resource and the newer `HTTPProxy` CRD, and is adding support for the Kubernetes Gateway API.

---

## Envoy Gateway

[Envoy Gateway](https://gateway.envoyproxy.io) is a CNCF project that implements the **Kubernetes Gateway API** using Envoy as the data plane. It is the recommended ingress solution for Kubernetes clusters and is used in Atlas IDP.

Key design principles:
- Targets application developers, not just platform engineers
- Implements Kubernetes Gateway API (GatewayClass, Gateway, HTTPRoute)
- Extensible via `EnvoyProxy` and `BackendTrafficPolicy` CRDs
- Manages the full lifecycle of Envoy deployments

---

## Istio

Istio uses Envoy as its sidecar proxy. `istiod` (the Istio control plane) implements xDS and pushes configuration to all Envoy sidecars in the mesh.

**Istio xDS flow:**
```
kubectl apply -f virtualservice.yaml
       │
       ▼
  istiod (pilot)
  ├── Watches Kubernetes resources
  ├── Translates to xDS
  └── Pushes to all Envoy sidecars via ADS
```

---

## Control Plane Comparison

| Control Plane | Use Case | Gateway API Support |
|---|---|---|
| **go-control-plane** | Build your own | No (library) |
| **Contour** | Kubernetes ingress | Partial |
| **Envoy Gateway** | Kubernetes ingress (recommended) | Full |
| **Istio** | Service mesh | Partial (via Gateway) |
| **AWS App Mesh** | AWS-native service mesh | No |

---

## Summary

The control plane is the "brain" that programs Envoy's behavior. For Atlas IDP on AKS, **Envoy Gateway** is the right control plane — it provides a clean Kubernetes-native API (Gateway API) and manages Envoy instances automatically.

---

## Knowledge Check

1. What is the difference between a control plane and a data plane?
2. What problem does go-control-plane solve?
3. Why is Envoy Gateway preferred over Contour for new deployments?
4. How does Istio use Envoy?
