# Envoy Patterns in an IDP

## Context

An IDP built on Azure Kubernetes Service (AKS) using Crossplane for infrastructure provisioning and Flux for GitOps-based delivery. Envoy appears in the IDP as:

1. The data plane of Istio (installed as an AKS add-on)
2. The proxy engine behind Contour (an ingress controller alternative to NGINX Ingress)
3. A programmable traffic layer for developer platform services

## Pattern 1: Developer Portal Ingress (Backstage)

The Backstage developer portal is exposed to developers via an Envoy-backed ingress controller. Typical setup:

```yaml
# Contour HTTPProxy (Contour translates this to Envoy xDS)
apiVersion: projectcontour.io/v1
kind: HTTPProxy
metadata:
  name: backstage-proxy
  namespace: backstage
spec:
  virtualhost:
    fqdn: platform.atlas.example.com
    tls:
      secretName: backstage-tls
  routes:
    - conditions:
        - prefix: /
      services:
        - name: backstage
          port: 7007
      timeoutPolicy:
        response: 30s
        idle: 5m
```

## Pattern 2: Service-to-Service mTLS via Istio

Internal platform services (e.g., Backstage → backend plugin APIs) communicate via mTLS enforced by Istio's sidecar Envoy proxies. The policy is declared via PeerAuthentication:

```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: atlas-platform
spec:
  mtls:
    mode: STRICT    # All traffic in this namespace must use mTLS
```

## Pattern 3: Traffic Shifting for Platform Component Updates

When upgrading a platform service (e.g., a new version of an internal API), use Istio's VirtualService (backed by Envoy weighted clusters) to progressively shift traffic:

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: platform-api-vs
  namespace: atlas-platform
spec:
  hosts:
    - platform-api
  http:
    - route:
        - destination:
            host: platform-api
            subset: v1
          weight: 80
        - destination:
            host: platform-api
            subset: v2
          weight: 20
```

## Pattern 4: JWT Validation at the Edge

Developers accessing the platform APIs authenticate via Azure AD. Envoy (via Istio's RequestAuthentication) validates JWTs at the edge before requests reach backend services:

```yaml
apiVersion: security.istio.io/v1beta1
kind: RequestAuthentication
metadata:
  name: atlas-jwt
  namespace: atlas-platform
spec:
  jwtRules:
    - issuer: "https://sts.windows.net/<tenant-id>/"
      jwksUri: "https://login.microsoftonline.com/<tenant-id>/discovery/v2.0/keys"
      audiences:
        - "api://<atlas-client-id>"
```

Combined with AuthorizationPolicy (backed by Envoy RBAC filter) to enforce access per service.

## Pattern 5: Observability — Golden Signals from Envoy

Envoy sidecars emit the four golden signals for all service-to-service traffic without instrumentation:

- **Latency** — `upstream_rq_time` histogram per route
- **Traffic** — `upstream_rq_total` per cluster
- **Errors** — `upstream_rq_5xx` per cluster
- **Saturation** — `upstream_cx_active` and circuit breaker overflow counters

These are scraped by Prometheus and visualized in Grafana dashboards pre-built for Istio.
