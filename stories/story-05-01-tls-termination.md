# Story 05-01 — TLS Termination & mTLS

> **Flow:** [Advanced](../flows/flow-05-advanced.md)  
> **Effort:** ~45 minutes

---

## TLS in Envoy

Envoy supports three TLS modes for downstream (client-facing) connections:

| Mode | Description |
|---|---|
| **Terminate** | Envoy decrypts TLS and forwards plaintext upstream |
| **Passthrough** | Envoy forwards encrypted bytes without decrypting |
| **Re-encrypt** | Envoy decrypts, inspects, re-encrypts to upstream (mTLS) |

---

## TLS Termination Configuration

```yaml
filter_chains:
  - transport_socket:
      name: envoy.transport_sockets.tls
      typed_config:
        "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.DownstreamTlsContext
        common_tls_context:
          tls_certificates:
            - certificate_chain:
                filename: /etc/certs/server.crt
              private_key:
                filename: /etc/certs/server.key
          # Optional: require client certificate
          # validation_context:
          #   trusted_ca:
          #     filename: /etc/certs/ca.crt
        require_client_certificate: false
```

---

## Secret Discovery Service (SDS)

In Kubernetes, certificates rotate frequently. SDS allows Envoy to receive certificate updates dynamically — without restarting.

With cert-manager + SDS:
1. cert-manager issues a certificate and stores it as a Kubernetes Secret
2. SDS agent (e.g., `istio-agent` or custom) reads the Secret
3. SDS agent delivers the certificate to Envoy via gRPC
4. Envoy updates the TLS context — zero downtime

```yaml
# Reference an SDS-managed secret instead of a file
tls_certificates:
  - certificate_chain:
      sds:
        cluster_name: sds_cluster
        resource_name: my-service-cert
    private_key:
      sds:
        cluster_name: sds_cluster
        resource_name: my-service-cert
```

---

## Mutual TLS (mTLS)

In mTLS, both the client and server present certificates. This is used for service-to-service authentication in a mesh.

```yaml
# Upstream cluster with mTLS to backend
clusters:
  - name: backend_cluster
    transport_socket:
      name: envoy.transport_sockets.tls
      typed_config:
        "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.UpstreamTlsContext
        common_tls_context:
          tls_certificates:
            - certificate_chain:
                filename: /etc/certs/client.crt
              private_key:
                filename: /etc/certs/client.key
          validation_context:
            trusted_ca:
              filename: /etc/certs/ca.crt
        sni: backend-service.default.svc.cluster.local
```

---

## Azure Key Vault Integration

For Atlas IDP on AKS, certificates are typically stored in Azure Key Vault and synchronized to Kubernetes Secrets via **Azure Key Vault Provider for Secrets Store CSI Driver**:

```bash
# Install the CSI driver
helm install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver \
  -n kube-system

# Install Azure Key Vault provider
helm install akv2k8s spv-charts/akv2k8s -n akv2k8s
```

Envoy Gateway's `cert-manager` integration then issues and rotates certificates automatically.

---

## Summary

Envoy provides comprehensive TLS support from simple termination to mTLS for zero-trust service mesh patterns. For Atlas IDP, using SDS with cert-manager ensures certificates are automatically rotated without proxy downtime.

---

## Knowledge Check

1. What is the difference between TLS termination and TLS passthrough in Envoy?
2. Why is SDS preferred over file-based certificate loading in Kubernetes?
3. What does mTLS add compared to regular TLS?
4. How does Azure Key Vault integrate with Envoy certificate management in AKS?
