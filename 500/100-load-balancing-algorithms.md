# Load Balancing Algorithms

## Overview

Envoy selects an upstream endpoint for each request using a configurable **load balancing policy** set on the cluster. The right policy depends on your traffic pattern.

## Round Robin (default)

Distributes requests sequentially across endpoints in order. Good for uniform, stateless, short-lived requests.

```yaml
lb_policy: ROUND_ROBIN
```

**Problem with gRPC**: gRPC uses long-lived HTTP/2 streams. Round-robin assigns connections, not requests. Once a connection is established to an endpoint, all gRPC requests over that connection go to the same pod — effectively defeating load balancing. Use `LEAST_REQUEST` for gRPC.

## Least Request

Routes each new request to the endpoint with the fewest active requests.

```yaml
lb_policy: LEAST_REQUEST
least_request_lb_config:
  choice_count: 2   # Power of two choices: compare 2 random endpoints, pick the least loaded
```

Best for: variable-length requests, gRPC streaming, computationally expensive endpoints.

## Random

Picks an endpoint at random. Simple and effective when all endpoints are homogeneous.

```yaml
lb_policy: RANDOM
```

## Ring Hash (Consistent Hashing)

Maps requests to endpoints using a hash ring. Requests with the same hash key (e.g., user ID in a header) consistently go to the same endpoint.

```yaml
lb_policy: RING_HASH
ring_hash_lb_config:
  minimum_ring_size: 1024
  maximum_ring_size: 8388608

# Hash policy defined on the route:
routes:
  - match:
      prefix: "/"
    route:
      cluster: my_cluster
      hash_policy:
        - header:
            header_name: "x-user-id"
```

Use for: session affinity, cache locality, stateful services where a user should always reach the same instance.

## Maglev

Google's consistent hashing algorithm. Provides minimal disruption when endpoints are added or removed (fewer keys are remapped than with ring hash).

```yaml
lb_policy: MAGLEV
```

## Zone-Aware Routing

When endpoints are in multiple availability zones, Envoy prefers endpoints in the same zone as the proxy:

```yaml
common_lb_config:
  zone_aware_lb_config:
    routing_enabled:
      value: 100   # 100% zone-aware
    min_cluster_size: 6   # Only activate zone-aware routing if ≥6 endpoints
```

This reduces cross-zone network costs in cloud environments like Azure.
