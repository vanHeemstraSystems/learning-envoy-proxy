# Story 04-02 — Kubernetes Gateway API

> **Flow:** [Kubernetes](../flows/flow-04-kubernetes.md)  
> **Effort:** ~45 minutes  
> **Next:** [Story 04-03 — Envoy Gateway](story-04-03-envoy-gateway.md)

---

## What is the Kubernetes Gateway API?

The **Kubernetes Gateway API** is the next-generation ingress specification for Kubernetes, designed to replace the legacy `Ingress` resource. It was developed by the Kubernetes SIG-Network group and is now GA for core features.

Key improvements over `Ingress`:

| Problem with Ingress | Gateway API Solution |
|---|---|
| Non-standard annotations for routing | First-class routing resources |
| No role separation | GatewayClass (infra), Gateway (ops), Route (dev) |
| No TCP/UDP support | Supports TCPRoute, UDPRoute, TLSRoute |
| No traffic splitting | HTTPRoute supports weight-based routing |
| Vendor-specific features via annotations | Extensible via policy attachment |

---

## The Resource Model

```
GatewayClass       → Defines the controller implementation (e.g., Envoy Gateway)
  └── Gateway      → Defines a load balancer instance (ports, TLS)
        └── HTTPRoute → Defines routing rules (paths, headers, weights)
              └── Service → Backend service
```

### GatewayClass

Installed once by the platform engineer. References the Envoy Gateway controller.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: envoy-gateway
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
```

### Gateway

Defines a load balancer. Created by the ops team per environment.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: atlas-gateway
  namespace: ingress
spec:
  gatewayClassName: envoy-gateway
  listeners:
    - name: http
      protocol: HTTP
      port: 80
    - name: https
      protocol: HTTPS
      port: 443
      tls:
        mode: Terminate
        certificateRefs:
          - name: atlas-tls-cert
```

### HTTPRoute

Defines routing rules. Created by developers per service.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-service-route
  namespace: my-app
spec:
  parentRefs:
    - name: atlas-gateway
      namespace: ingress
  hostnames:
    - "my-service.atlas.example.com"
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /api
      backendRefs:
        - name: my-service
          port: 8080
          weight: 90
        - name: my-service-canary
          port: 8080
          weight: 10    # 10% canary traffic
```

---

## Role Separation

| Role | Resource | Who manages it |
|---|---|---|
| Infrastructure Provider | GatewayClass | Platform engineer |
| Cluster Operator | Gateway | Ops / Platform team |
| Application Developer | HTTPRoute, TCPRoute | Dev team |

This is a major improvement over `Ingress` where all configuration lived in one resource.

---

## Route Types

| Route Type | Protocol | Status |
|---|---|---|
| HTTPRoute | HTTP/HTTPS/gRPC | GA |
| TCPRoute | TCP | Experimental |
| TLSRoute | TLS (passthrough) | Experimental |
| UDPRoute | UDP | Experimental |
| GRPCRoute | gRPC (typed) | GA |

---

## Summary

The Kubernetes Gateway API provides a clean, role-based model for managing ingress in Kubernetes. Envoy Gateway implements this API using Envoy as the data plane. For Atlas IDP, HTTPRoute and GRPCRoute are the primary resources you will use for service routing.

---

## Knowledge Check

1. What are the three primary Gateway API resources and who manages each?
2. How does weight-based routing work in HTTPRoute?
3. What is the purpose of GatewayClass?
4. How does the Gateway API improve role separation compared to `Ingress`?
