# Endpoints

## What Is an Endpoint?

An endpoint is a specific network address (IP + port) of an upstream host within a cluster. In static configuration, endpoints are embedded directly in the cluster's `load_assignment`. In dynamic configuration (EDS), they are pushed by the control plane.

## Static Endpoints

```yaml
load_assignment:
  cluster_name: my_cluster
  endpoints:
    - locality:
        region: westeurope
        zone: westeurope-1
      lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: 10.0.1.5
                port_value: 8080
          load_balancing_weight: 1
        - endpoint:
            address:
              socket_address:
                address: 10.0.1.6
                port_value: 8080
          load_balancing_weight: 1
```

## Locality and Load Balancing Weight

Endpoints can be grouped by **locality** (region, zone, sub-zone). Envoy uses locality to implement **zone-aware routing** — preferring endpoints in the same zone to reduce latency and cross-zone traffic costs in cloud environments like Azure.

`load_balancing_weight` allows assigning relative weights to endpoints or localities. An endpoint with weight 2 will receive approximately twice as much traffic as one with weight 1.

## Health Status

Each endpoint has an associated health status:

- `HEALTHY` — Eligible to receive traffic
- `UNHEALTHY` — Excluded from the load balancer
- `DRAINING` — Envoy will not send new requests (used for graceful shutdown)
- `UNKNOWN` — Initial state; treated as healthy

Health status is updated by:

1. **Active health checking** — Envoy periodically sends health check requests
2. **Passive health checking (outlier detection)** — Envoy monitors error rates and ejects bad endpoints automatically
3. **EDS** — The control plane explicitly sets endpoint health status

## Outlier Detection

Outlier detection automatically ejects endpoints exhibiting errors:

```yaml
outlier_detection:
  consecutive_5xx: 5           # Eject after 5 consecutive 5xx responses
  interval: 10s
  base_ejection_time: 30s
  max_ejection_percent: 10     # Never eject more than 10% of endpoints
```

This is complementary to active health checking and provides faster, more granular failure detection.
