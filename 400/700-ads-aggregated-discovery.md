# Aggregated Discovery Service (ADS)

## What ADS Is

ADS multiplexes all xDS resource types (LDS, RDS, CDS, EDS, SDS) onto a **single gRPC bidirectional stream**. Instead of maintaining separate connections for each xDS type, Envoy connects to one ADS server and receives all resource updates through that single stream.

## Why ADS?

Using separate LDS, RDS, CDS, EDS connections introduces a **consistency problem**. Consider this scenario:

1. CDS pushes a new cluster `my_new_service`.
2. RDS pushes a route that references `my_new_service`.
3. If RDS update arrives before CDS is processed, Envoy references an unknown cluster — requests fail.

ADS solves this by allowing the control plane to **order updates on a single stream**, ensuring dependent resources are pushed in the correct sequence: CDS first, then EDS, then LDS, then RDS.

## ADS Configuration

```yaml
dynamic_resources:
  ads_config:
    api_type: GRPC
    transport_api_version: V3
    grpc_services:
      - envoy_grpc:
          cluster_name: xds_cluster
  lds_config:
    ads: {}          # Use ADS for LDS
  cds_config:
    ads: {}          # Use ADS for CDS
```

## Ordering Rules for ADS

The control plane **must** follow this ordering when sending updates:

1. **CDS** resources (clusters must exist before routes reference them)
2. **EDS** resources (endpoints for the new clusters)
3. **LDS** resources (listeners reference route configs and clusters)
4. **RDS** resources (routes reference clusters — sent last)

Envoy will NACK a resource that references an unknown dependency.

## ADS in Production

All major Envoy control planes (Istio istiod, Contour, AWS App Mesh) use ADS in production. When building a custom control plane, always use the [go-control-plane](https://github.com/envoyproxy/go-control-plane) library, which handles ADS ordering automatically.
