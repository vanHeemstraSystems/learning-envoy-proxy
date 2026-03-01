# Istio and Envoy

## The Relationship

Istio is a service mesh platform. Envoy is its data plane — the component that actually handles network traffic. Istio's control plane (**istiod**) translates Kubernetes resources (Service, ServiceEntry, VirtualService, DestinationRule, PeerAuthentication, AuthorizationPolicy) into Envoy xDS configuration and pushes it to each sidecar via ADS.

## Istio Control Plane → Envoy Translation

| Istio Resource | Envoy Equivalent |
|---|---|
| `VirtualService` | Route configuration (RDS) |
| `DestinationRule` | Cluster configuration (CDS) with LB, mTLS, circuit breakers |
| `ServiceEntry` | Cluster for external services |
| `PeerAuthentication` | Downstream TLS context (require mTLS) |
| `AuthorizationPolicy` | RBAC filter configuration |
| `RequestAuthentication` | jwt_authn filter configuration |
| `Sidecar` | Which listeners/clusters each sidecar needs |

## Istio-Specific Envoy Ports

When Istio injects a sidecar, it adds iptables rules that redirect pod traffic:

| Port | Purpose |
|---|---|
| 15001 | Envoy outbound listener (egress traffic from app) |
| 15006 | Envoy inbound listener (ingress traffic to app) |
| 15000 | Envoy admin API |
| 15020 | Merged Prometheus metrics (Pilot agent) |
| 15090 | Envoy Prometheus metrics |

Traffic that the app sends to port 8080 is intercepted by iptables and redirected to port 15001 (Envoy outbound). Envoy routes it to the correct upstream, applying all policies.

## Inspecting Istio-Managed Envoy Config

```bash
# Dump the full Envoy config (this is complex — thousands of lines)
istioctl proxy-config dump pod/my-pod-xxx

# View only clusters
istioctl proxy-config cluster pod/my-pod-xxx

# View only listeners
istioctl proxy-config listener pod/my-pod-xxx

# View routes
istioctl proxy-config route pod/my-pod-xxx

# Check mTLS status
istioctl authn tls-check pod/my-pod-xxx my-service.my-namespace.svc.cluster.local
```

## EnvoyFilter — Direct Envoy Configuration Patching

When Istio's high-level resources are insufficient, you can patch Envoy config directly via `EnvoyFilter`:

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: add-response-header
  namespace: my-namespace
spec:
  workloadSelector:
    labels:
      app: my-service
  configPatches:
    - applyTo: HTTP_FILTER
      match:
        context: SIDECAR_INBOUND
        listener:
          filterChain:
            filter:
              name: "envoy.filters.network.http_connection_manager"
      patch:
        operation: INSERT_BEFORE
        value:
          name: envoy.filters.http.lua
          typed_config:
            "@type": type.googleapis.com/envoy.extensions.filters.http.lua.v3.LuaPerRoute
            default_source_code:
              inline_string: |
                function envoy_on_response(response_handle)
                  response_handle:headers():add("x-service-version", "v2")
                end
```

Use `EnvoyFilter` sparingly — it bypasses Istio's abstraction layer and can break with Istio version upgrades.
