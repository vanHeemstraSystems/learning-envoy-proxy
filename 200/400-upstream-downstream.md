# Upstream and Downstream

## Definitions

**Downstream** refers to traffic flowing **toward** Envoy — i.e., clients sending requests to Envoy. Downstream connections originate from clients (browsers, other services, ingress traffic).

**Upstream** refers to traffic flowing **away from** Envoy — i.e., Envoy forwarding requests to backend services. Upstream connections terminate at application endpoints (pods, VMs, external APIs).

```
[Downstream Client] ---request---> [Envoy] ---request---> [Upstream Service]
[Downstream Client] <--response--- [Envoy] <--response--- [Upstream Service]
```

## Why the Terminology Matters

Envoy's configuration, metrics, and logs use "upstream" and "downstream" consistently:

- `downstream_cx_total` — total downstream connections received by Envoy
- `upstream_cx_total` — total upstream connections opened by Envoy to clusters
- `downstream_rq_total` — total downstream requests
- `upstream_rq_total` — total upstream requests forwarded

When reading Envoy logs or dashboards, always orient yourself: "Am I looking at the client side (downstream) or the backend side (upstream)?"

## In a Sidecar Context

In a service mesh with sidecar proxies:

- **Ingress sidecar**: traffic from other services arrives as downstream, is proxied upstream to the local application
- **Egress sidecar**: traffic from the local application arrives as downstream (outbound), is proxied upstream to a remote service's sidecar

Each Envoy sidecar is simultaneously a downstream receiver and an upstream forwarder.

## Connection Pools

Envoy maintains separate **connection pools** for each upstream cluster. Connections in the pool are reused across multiple downstream requests, reducing the overhead of establishing new connections to upstream services. Pool behavior (max connections, pending requests, retries) is configured in the cluster's `circuit_breakers` settings.
