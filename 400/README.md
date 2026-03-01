# 400 - Dynamic Configuration (xDS API)

The xDS API is what makes Envoy suitable for Kubernetes and service meshes. Instead of static YAML, a **control plane** pushes configuration to Envoy at runtime — no restarts required.

## Contents

| File | Description |
|---|---|
| [100-xds-overview.md](100-xds-overview.md) | What xDS is and why it exists |
| [200-lds-listener-discovery.md](200-lds-listener-discovery.md) | Listener Discovery Service |
| [300-rds-route-discovery.md](300-rds-route-discovery.md) | Route Discovery Service |
| [400-cds-cluster-discovery.md](400-cds-cluster-discovery.md) | Cluster Discovery Service |
| [500-eds-endpoint-discovery.md](500-eds-endpoint-discovery.md) | Endpoint Discovery Service |
| [600-sds-secret-discovery.md](600-sds-secret-discovery.md) | Secret Discovery Service (TLS certs) |
| [700-ads-aggregated-discovery.md](700-ads-aggregated-discovery.md) | Aggregated Discovery Service |

## Lab

`examples/xds-control-plane/` contains a minimal Python gRPC control plane server and an Envoy configuration that connects to it. Add and remove clusters from the control plane to see Envoy update without restarting.
