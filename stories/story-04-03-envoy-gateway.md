# Story 04-03 — Envoy Gateway (CNCF Project)

> **Flow:** [Kubernetes](../flows/flow-04-kubernetes.md)  
> **Effort:** ~60 minutes  
> **Task:** [Task 04-02 — Envoy Gateway on AKS](../tasks/task-04-02-envoy-gateway-aks.md)

---

## What is Envoy Gateway?

[Envoy Gateway](https://gateway.envoyproxy.io) is a CNCF project (incubating) that provides a **production-grade implementation of the Kubernetes Gateway API** using Envoy as the data plane. It was launched in 2022 with backing from Tetrate, Ambassador Labs, and VMware.

**Design goals:**
- Easy to use for application developers (Gateway API abstraction)
- Fully extensible for platform engineers (via CRD policies)
- Manages the full lifecycle of Envoy deployments (deployment, scaling, config)

---

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                     │
│                                                           │
│  ┌──────────────────────────────────────────────────┐    │
│  │              Envoy Gateway Control Plane          │    │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────────────┐  │    │
│  │  │ Gateway  │ │  xDS     │ │  Status          │  │    │
│  │  │Controller│ │ Server   │ │  Manager         │  │    │
│  │  └──────────┘ └──────────┘ └──────────────────┘  │    │
│  └──────────────────────────────────────────────────┘    │
│           │ xDS (gRPC)                                    │
│           ▼                                               │
│  ┌──────────────────────────────────────────────────┐    │
│  │              Envoy Proxy (Data Plane)             │    │
│  │  Managed Deployment — Envoy Gateway creates it    │    │
│  └──────────────────────────────────────────────────┘    │
│           │                                               │
│           ▼ Traffic                                       │
│       Services                                            │
└──────────────────────────────────────────────────────────┘
```

---

## Installation on AKS

```bash
# Install Envoy Gateway using Helm
helm install envoy-gateway oci://docker.io/envoyproxy/gateway-helm \
  --version v1.1.0 \
  -n envoy-gateway-system \
  --create-namespace

# Verify installation
kubectl get pods -n envoy-gateway-system
kubectl get gatewayclass

# Apply GatewayClass
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: eg
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
EOF
```

---

## Extended Policies

Envoy Gateway extends the Gateway API with **Policy Attachment** resources:

| Policy CRD | Purpose |
|---|---|
| `BackendTrafficPolicy` | Retries, timeouts, circuit breaking per backend |
| `ClientTrafficPolicy` | Connection limits, keep-alive, TLS min version |
| `SecurityPolicy` | JWT authentication, CORS, Basic Auth |
| `EnvoyPatchPolicy` | Direct Envoy xDS patch (escape hatch) |
| `EnvoyExtensionPolicy` | External authorization, WASM filters |

```yaml
# Example: Set retry policy on a backend
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: BackendTrafficPolicy
metadata:
  name: retry-policy
spec:
  targetRef:
    group: gateway.networking.k8s.io
    kind: HTTPRoute
    name: my-service-route
  retry:
    numRetries: 3
    retryOn:
      - "5xx"
      - "gateway-error"
    perRetryPolicy:
      timeout: 2s
  timeout:
    request: 30s
```

---

## Azure Integration

When deployed on AKS, Envoy Gateway creates an Azure Load Balancer automatically via the Kubernetes LoadBalancer service type:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: atlas-gateway
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-internal: "false"  # Public LB
spec:
  gatewayClassName: eg
  listeners:
    - name: https
      protocol: HTTPS
      port: 443
      tls:
        mode: Terminate
        certificateRefs:
          - name: atlas-tls   # cert-manager managed secret
```

---

## Summary

Envoy Gateway is the recommended ingress controller for Atlas IDP on AKS. It provides a clean Kubernetes-native API (Gateway API), manages Envoy's lifecycle automatically, and extends the spec with production-grade policies for retries, timeouts, and security.

---

## Knowledge Check

1. What is Envoy Gateway's role in the control plane vs. data plane?
2. Which Envoy Gateway CRD would you use to configure JWT authentication?
3. How does Envoy Gateway create an Azure Load Balancer?
4. What is `EnvoyPatchPolicy` and when would you use it?
