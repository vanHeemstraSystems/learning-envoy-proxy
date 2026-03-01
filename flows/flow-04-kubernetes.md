# Flow 04 — Envoy in Kubernetes / AKS

## Goal

Deploy and operate Envoy in Kubernetes environments, covering the sidecar pattern, the Kubernetes Gateway API specification, and the Envoy Gateway CNCF project as a production-ready ingress solution for AKS.

## Why This Matters

The Atlas IDP platform runs on AKS. Envoy Gateway is the recommended ingress controller for Kubernetes Gateway API implementations and is a core component of cloud-native platform engineering patterns.

## Stories in This Flow

| # | Story | Effort |
|---|---|---|
| 04-01 | [Envoy as a Sidecar Container](../stories/story-04-01-envoy-as-sidecar.md) | 45 min |
| 04-02 | [Kubernetes Gateway API](../stories/story-04-02-gateway-api.md) | 45 min |
| 04-03 | [Envoy Gateway (CNCF Project)](../stories/story-04-03-envoy-gateway.md) | 60 min |

## Tasks in This Flow

| # | Task | Effort |
|---|---|---|
| 04-01 | [Sidecar Deployment](../tasks/task-04-01-sidecar-deployment.md) | 45 min |
| 04-02 | [Envoy Gateway on AKS](../tasks/task-04-02-envoy-gateway-aks.md) | 60 min |

## Learning Outcomes

By the end of this flow you will be able to:

- Deploy Envoy as a sidecar proxy alongside an application container in Kubernetes
- Explain iptables traffic interception used by service meshes
- Describe the Kubernetes Gateway API resources: GatewayClass, Gateway, HTTPRoute
- Install Envoy Gateway on AKS using Helm
- Configure HTTPRoutes to route traffic to backend services
- Integrate Envoy Gateway with Azure Load Balancer for external traffic

## Estimated Total Time

~4 hours (reading + hands-on)

---

*Previous: [Flow 03 — Observability](flow-03-observability.md)*  
*Next: [Flow 05 — Advanced](flow-05-advanced.md)*
