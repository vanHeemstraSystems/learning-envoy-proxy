# Endpoint Discovery Service (EDS)

## What EDS Manages

EDS pushes **ClusterLoadAssignment** resources to Envoy — the list of healthy IP:port endpoints for a given cluster. This is the most frequently updated xDS resource in a Kubernetes environment, changing every time a pod starts or stops.

## EDS Resource Structure

```json
{
  "cluster_name": "my_service_eds",
  "endpoints": [
    {
      "locality": {
        "region": "westeurope",
        "zone": "westeurope-1"
      },
      "lb_endpoints": [
        {
          "endpoint": {
            "address": {
              "socket_address": {
                "address": "10.244.1.5",
                "port_value": 8080
              }
            }
          },
          "health_status": "HEALTHY",
          "load_balancing_weight": 1
        }
      ]
    }
  ],
  "policy": {
    "overprovisioning_factor": 140
  }
}
```

## Health Status via EDS

The control plane can explicitly set endpoint health status to `HEALTHY`, `UNHEALTHY`, or `DRAINING`. This is how Kubernetes pod termination is handled:

1. Pod receives SIGTERM.
2. Control plane (e.g., istiod) marks the endpoint as `DRAINING` via EDS.
3. Envoy stops sending new requests to the endpoint.
4. In-flight requests complete.
5. Pod terminates after its grace period.

## Locality-Weighted Load Balancing

When endpoints are grouped by locality, EDS can assign different weights to localities, enabling region-level or zone-level traffic distribution.
