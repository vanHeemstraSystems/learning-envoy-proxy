# Envoy on Azure Kubernetes Service (AKS)

## Envoy in AKS — Integration Points

AKS does not run Envoy by default, but Envoy enters the picture through several add-ons and components:

| Component | Envoy Role | Enablement |
|---|---|---|
| Istio AKS Add-on | Sidecar proxy for all pods in labeled namespaces | `az aks enable-addons --addons istio` |
| Contour Ingress | Ingress controller backed by Envoy | Helm chart or GitOps |
| Application Gateway Ingress Controller (AGIC) | Uses Azure App Gateway (not Envoy) | AKS add-on |
| Open Service Mesh (OSM) | Envoy-based service mesh (deprecated in favor of Istio add-on) | Legacy only |

## Istio AKS Add-on

Microsoft's managed Istio add-on for AKS uses Envoy sidecars and is the recommended path for service mesh capabilities:

```bash
# Enable Istio add-on
az aks update \
  --resource-group my-rg \
  --name my-aks-cluster \
  --enable-asm

# Enable sidecar injection for a namespace
kubectl label namespace my-app istio.io/rev=asm-1-19
```

The Istio add-on manages Envoy sidecar lifecycle, certificate rotation (via SDS), and xDS configuration push (via istiod running as an AKS-managed component).

## Network Policy Interaction

In AKS, **Azure CNI** with **Calico** network policies coexist with Istio mTLS. Be aware:

- Network policies operate at L3/L4 (IP + port)
- Istio mTLS operates at L7 (application layer within TLS)
- Both enforce independently — a pod can have a network policy blocking TCP 8080 AND an Istio PeerAuthentication requiring mTLS

For Istio to function correctly, network policies must allow traffic on port `15006` (Envoy inbound) and `15001` (Envoy outbound) between pods.

## AKS Workload Identity + Envoy

When platform services need to authenticate to Azure resources (Key Vault, Storage, Azure AD), use **AKS Workload Identity**. Envoy itself does not need to handle Azure AD authentication for the application — the application pod's service account is federated with Azure AD and receives tokens directly from the Azure IMDS endpoint.

However, Envoy's ext_authz filter or jwt_authn filter can validate the tokens that applications obtain, ensuring only properly authorized clients reach platform APIs.

## Resource Sizing Envoy Sidecars on AKS

Default Istio sidecar resource requests are conservative. For production AKS workloads:

```yaml
# IstioOperator or MeshConfig override
meshConfig:
  defaultConfig:
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 256Mi
```

Monitor sidecar CPU and memory via the `container_cpu_usage_seconds_total` and `container_memory_working_set_bytes` metrics filtered for `container="istio-proxy"`.
