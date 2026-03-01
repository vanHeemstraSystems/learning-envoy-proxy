# Secret Discovery Service (SDS)

## What SDS Manages

SDS pushes **TLS certificates, private keys, and CA certificates** to Envoy. This enables automatic certificate rotation without restarting Envoy or reloading listeners.

## Why SDS?

Without SDS, TLS certificates are embedded in the static Envoy configuration. Rotating a certificate requires updating the config file and reloading Envoy. In a service mesh where every sidecar has a short-lived mTLS certificate (e.g., 24-hour lifetime), this would be impractical.

SDS allows Istio's **istiod** (or another certificate authority) to push new certificates to every Envoy sidecar automatically, seconds before the old ones expire.

## SDS Configuration

TLS contexts reference SDS resources by name instead of embedding raw PEM data:

```yaml
transport_socket:
  name: envoy.transport_sockets.tls
  typed_config:
    "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.DownstreamTlsContext
    common_tls_context:
      tls_certificate_sds_secret_configs:
        - name: server_cert            # SDS resource name
          sds_config:
            resource_api_version: V3
            api_config_source:
              api_type: GRPC
              transport_api_version: V3
              grpc_services:
                - envoy_grpc:
                    cluster_name: sds_cluster
      validation_context_sds_secret_config:
        name: validation_context
        sds_config:
          # same sds_config as above
```

## SDS Secret Resource

```json
{
  "name": "server_cert",
  "tls_certificate": {
    "certificate_chain": {"inline_string": "-----BEGIN CERTIFICATE-----\n..."},
    "private_key": {"inline_string": "-----BEGIN EC PRIVATE KEY-----\n..."}
  }
}
```

## Security Note

SDS eliminates the need to write private keys to disk. In Kubernetes, private keys from a CA can be pushed directly to the Envoy process memory via SDS, reducing the risk of key exfiltration from the filesystem.
