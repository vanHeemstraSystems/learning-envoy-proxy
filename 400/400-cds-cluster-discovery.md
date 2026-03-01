# Cluster Discovery Service (CDS)

## What CDS Manages

CDS pushes **Cluster** resources to Envoy, allowing dynamic addition, modification, and removal of upstream services without restarting Envoy.

## CDS Configuration in Bootstrap

```yaml
dynamic_resources:
  cds_config:
    resource_api_version: V3
    api_config_source:
      api_type: GRPC
      transport_api_version: V3
      grpc_services:
        - envoy_grpc:
            cluster_name: xds_cluster
```

## CDS and EDS Relationship

CDS and EDS are tightly linked:

- CDS pushes the cluster definition (name, LB policy, health check config, circuit breakers)
- EDS pushes the actual endpoint IP:port list for that cluster

When a CDS cluster uses `type: EDS`, Envoy automatically subscribes to EDS for the corresponding endpoints.

```json
{
  "name": "my_service",
  "type": "EDS",
  "eds_cluster_config": {
    "eds_config": {
      "resource_api_version": "V3",
      "api_config_source": {
        "api_type": "GRPC",
        "transport_api_version": "V3",
        "grpc_services": [{"envoy_grpc": {"cluster_name": "xds_cluster"}}]
      }
    },
    "service_name": "my_service_eds"
  },
  "connect_timeout": "0.25s",
  "lb_policy": "ROUND_ROBIN"
}
```

## Cluster Update Semantics

When a cluster is updated via CDS:

- Envoy drains existing connections to the old cluster version gradually
- New requests use the updated cluster immediately
- Connection pools to the old endpoints are closed after the drain period
