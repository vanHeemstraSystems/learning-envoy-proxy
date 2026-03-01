# Story 02-02 — xDS Dynamic Configuration API

> **Flow:** [Configuration](../flows/flow-02-configuration.md)  
> **Effort:** ~60 minutes  
> **Previous:** [Story 02-01 — Static Config](story-02-01-static-config.md)  
> **Next:** [Story 02-03 — Control Plane](story-02-03-control-plane.md)  
> **Task:** [Task 02-02 — xDS Server in Python](../tasks/task-02-02-xds-server-python.md)

---

## What is xDS?

**xDS** stands for "x Discovery Service" — a family of APIs that allow an external **control plane** to push configuration to Envoy at runtime, without requiring a restart. The "x" is a wildcard for the different resource types.

This is the core mechanism that makes Envoy dynamic — the same capability that allows Istio to update routing rules across thousands of Envoy sidecars instantly when a Kubernetes Service changes.

---

## The Six xDS Resource Types

| API | Full Name | What it configures |
|---|---|---|
| **LDS** | Listener Discovery Service | Listeners (ports, filter chains) |
| **RDS** | Route Discovery Service | Route configurations (virtual hosts, routes) |
| **CDS** | Cluster Discovery Service | Clusters (upstream service definitions) |
| **EDS** | Endpoint Discovery Service | Endpoints (IP:port pairs in each cluster) |
| **SDS** | Secret Discovery Service | TLS certificates and keys |
| **RTDS** | Runtime Discovery Service | Runtime flag overrides |

The most common flow:

```
CDS → EDS → LDS → RDS
```

Clusters must be known before endpoints. Listeners must be known before routes.

---

## Discovery Modes

### State of the World (SotW)
The control plane sends the **complete set** of resources on every update. Envoy replaces its entire resource collection.

```
Control Plane ──▶ Envoy
  "Here are all your clusters: [a, b, c]"
  "Here are all your clusters: [a, b]"   (c was removed)
```

### Delta xDS (Incremental)
The control plane sends only **changes** — added, modified, or removed resources. More efficient for large configurations.

```
Control Plane ──▶ Envoy
  "Add cluster c"
  "Remove cluster b"
```

---

## Transport Protocols

xDS can be delivered via:

| Transport | Use Case |
|---|---|
| **gRPC (streaming)** | Production — bidirectional streaming, efficient |
| **REST+LongPoll** | Legacy — simpler but less efficient |

Modern deployments always use gRPC.

---

## ADS — Aggregated Discovery Service

**ADS** (Aggregated Discovery Service) multiplexes all xDS resource types over a **single gRPC connection**. This is the recommended approach because it:

- Reduces connection overhead
- Ensures ordering guarantees (clusters before listeners)
- Simplifies control plane implementation

```yaml
dynamic_resources:
  ads_config:
    api_type: GRPC
    transport_api_version: V3
    grpc_services:
      - envoy_grpc:
          cluster_name: xds_cluster
  cds_config:
    resource_api_version: V3
    ads: {}
  lds_config:
    resource_api_version: V3
    ads: {}

static_resources:
  clusters:
    - name: xds_cluster
      type: STATIC
      connect_timeout: 5s
      http2_protocol_options: {}    # gRPC requires HTTP/2
      load_assignment:
        cluster_name: xds_cluster
        endpoints:
          - lb_endpoints:
              - endpoint:
                  address:
                    socket_address:
                      address: control-plane.example.com
                      port_value: 18000
```

---

## xDS Protocol Flow

```
Envoy (xDS client)                    Control Plane (xDS server)
        │                                       │
        │── DiscoveryRequest ─────────────────▶ │
        │   { type_url: "...Cluster",            │
        │     version_info: "",                  │
        │     resource_names: [] }               │
        │                                       │
        │ ◀─────────────────── DiscoveryResponse│
        │   { version_info: "v1",               │
        │     resources: [cluster_a, cluster_b] }│
        │                                       │
        │── ACK DiscoveryRequest ──────────────▶│
        │   { version_info: "v1" }              │
        │                                       │
        │    [control plane detects a change]    │
        │                                       │
        │ ◀─────────────────── DiscoveryResponse│
        │   { version_info: "v2",               │
        │     resources: [cluster_a] }           │  (cluster_b removed)
        │                                       │
        │── ACK DiscoveryRequest ──────────────▶│
```

If Envoy cannot apply a new version (e.g., invalid config), it sends a **NACK** — a DiscoveryRequest with the old `version_info` and an `error_detail` field. The control plane must retain the previous valid version until ACK is received.

---

## xDS API Versioning

| Version | Status | Notes |
|---|---|---|
| v1 | Deprecated | No longer supported |
| v2 | Deprecated | Removed in Envoy 1.24+ |
| **v3** | **Current** | Always use v3 |

Always specify `transport_api_version: V3` and `resource_api_version: V3` in your config.

---

## Resource Type URLs

When making xDS requests, resources are identified by their protobuf type URL:

| Resource | Type URL |
|---|---|
| Listener | `type.googleapis.com/envoy.config.listener.v3.Listener` |
| RouteConfiguration | `type.googleapis.com/envoy.config.route.v3.RouteConfiguration` |
| Cluster | `type.googleapis.com/envoy.config.cluster.v3.Cluster` |
| ClusterLoadAssignment | `type.googleapis.com/envoy.config.endpoint.v3.ClusterLoadAssignment` |
| Secret | `type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.Secret` |

---

## Practical Implication for Atlas IDP

When Envoy Gateway runs on AKS as part of Atlas IDP:

1. You create a `Gateway` and `HTTPRoute` Kubernetes resource
2. The Envoy Gateway **control plane** (running as a Kubernetes controller) watches these resources
3. The control plane translates them into Envoy xDS resources (Listeners, Routes, Clusters)
4. The control plane pushes these to the Envoy data plane via ADS
5. Traffic flows according to the new configuration — with zero downtime

You don't write xDS YAML directly — Kubernetes Gateway API resources are the abstraction layer.

---

## Summary

xDS is the protocol that makes Envoy a programmable proxy. The six discovery service types (LDS, RDS, CDS, EDS, SDS, RTDS) together cover all aspects of Envoy's configuration. ADS aggregates them over a single gRPC stream for efficiency. The control plane is responsible for implementing the xDS server and translating higher-level intent into Envoy configuration.

---

## Knowledge Check

1. What does "ADS" stand for and why is it preferred over individual xDS APIs?
2. What is the difference between SotW and Delta xDS?
3. In what order should xDS resources be delivered to Envoy and why?
4. What happens if Envoy cannot apply a new xDS configuration version?

---

*Task: [Task 02-02 — xDS Server in Python](../tasks/task-02-02-xds-server-python.md)*  
*Next: [Story 02-03 — Control Planes](story-02-03-control-plane.md)*
