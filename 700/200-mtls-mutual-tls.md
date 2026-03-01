# Mutual TLS (mTLS)

## What Is mTLS?

In standard TLS (one-way TLS), only the server presents a certificate. The client verifies it but remains anonymous to the server. In **mutual TLS (mTLS)**, both parties present certificates and verify each other. This proves identity in both directions.

In a service mesh, mTLS provides:

- **Authentication** — "I know this request came from the orders-service, not a rogue pod."
- **Encryption** — all traffic between services is encrypted in transit.
- **Integrity** — the payload cannot be tampered with.

## Envoy mTLS Configuration

**Downstream (accepting mTLS connections)**:

```yaml
filter_chains:
  - transport_socket:
      name: envoy.transport_sockets.tls
      typed_config:
        "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.DownstreamTlsContext
        require_client_certificate: true    # Enforce mTLS
        common_tls_context:
          tls_certificates:
            - certificate_chain:
                filename: /etc/certs/server.crt
              private_key:
                filename: /etc/certs/server.key
          validation_context:
            trusted_ca:
              filename: /etc/certs/ca.crt
```

**Upstream (initiating mTLS connections)**:

```yaml
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
    sni: target-service.default.svc.cluster.local
```

## mTLS in Service Meshes

In Istio, mTLS is configured via `PeerAuthentication` and `DestinationRule` resources. Istio's istiod:

1. Acts as a CA (signing SPIFFE SVIDs — X.509 certificates with a SPIFFE URI in the SAN)
2. Pushes certificates to Envoy sidecars via SDS
3. Rotates certificates before expiry (typically every 24 hours)
4. Configures both upstream and downstream TLS contexts automatically

The SPIFFE ID format used in Istio: `spiffe://cluster.local/ns/<namespace>/sa/<service-account>`

## Certificate Generation for Labs

```bash
# Generate CA key and certificate
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -sha256 -days 365 -out ca.crt \
  -subj "/CN=My Test CA"

# Generate server key and CSR
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr -subj "/CN=my-service"

# Sign server certificate with CA
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key \
  -CAcreateserial -out server.crt -days 365 -sha256
```
