# Traffic Splitting and Canary Deployments

## Weighted Cluster Routing

Envoy supports **weighted traffic splitting** at the route level. This enables canary deployments, A/B testing, and blue/green deployments without any application changes.

```yaml
routes:
  - match:
      prefix: "/"
    route:
      weighted_clusters:
        clusters:
          - name: my_service_v1
            weight: 90      # 90% of traffic to v1
          - name: my_service_v2
            weight: 10      # 10% of traffic to v2 (canary)
        total_weight: 100
```

## Header-Based Routing (Dark Launch)

Route a specific subset of users to the canary version based on a request header:

```yaml
virtual_hosts:
  - name: my_app
    domains: ["*"]
    routes:
      # Internal testers get the canary
      - match:
          prefix: "/"
          headers:
            - name: "x-canary"
              exact_match: "true"
        route:
          cluster: my_service_v2

      # Everyone else gets stable v1
      - match:
          prefix: "/"
        route:
          cluster: my_service_v1
```

## Mirroring (Shadow Traffic)

Send a copy of live traffic to a new version without affecting the response returned to clients. This is ideal for testing a new version under real load before routing actual users to it.

```yaml
routes:
  - match:
      prefix: "/"
    route:
      cluster: my_service_v1
      request_mirror_policies:
        - cluster: my_service_v2
          runtime_fraction:
            default_value:
              numerator: 10
              denominator: HUNDRED    # Mirror 10% of requests
```

The mirrored requests are sent fire-and-forget — their responses are discarded. The client only sees the response from `my_service_v1`.

## Progressive Delivery with Envoy + Flux

In the Atlas IDP, traffic splitting can be managed by **Flagger** (a Flux toolkit component) which:

1. Creates a Canary custom resource
2. Automatically adjusts Envoy weighted cluster percentages based on metrics (error rate, latency)
3. Rolls back automatically if error thresholds are exceeded
