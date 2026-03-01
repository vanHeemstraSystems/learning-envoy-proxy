# JWT Authentication

## Overview

Envoy's **jwt_authn** HTTP filter validates JSON Web Tokens (JWTs) on incoming requests. It verifies the signature, expiry, issuer, and audience without requiring any application code changes.

## JWT Filter Configuration

```yaml
http_filters:
  - name: envoy.filters.http.jwt_authn
    typed_config:
      "@type": type.googleapis.com/envoy.extensions.filters.http.jwt_authn.v3.JwtAuthentication
      providers:
        azure_ad:
          issuer: "https://sts.windows.net/<tenant-id>/"
          audiences:
            - "api://<client-id>"
          remote_jwks:
            http_uri:
              uri: "https://login.microsoftonline.com/<tenant-id>/discovery/v2.0/keys"
              cluster: jwks_cluster
              timeout: 5s
            cache_duration: 300s      # Cache JWKS for 5 minutes
          forward: true               # Forward the JWT to the upstream service
          payload_in_metadata: "jwt_payload"   # Store decoded payload in filter metadata

      rules:
        - match:
            prefix: "/api/public"
          # No requirements — unauthenticated access allowed

        - match:
            prefix: "/api/private"
          requires:
            provider_name: "azure_ad"

        - match:
            prefix: "/"
          requires:
            provider_name: "azure_ad"

  - name: envoy.filters.http.router
    typed_config:
      "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router
```

## Extracting JWT Claims for RBAC

After jwt_authn validates a token, it stores the decoded payload in filter metadata under the key specified in `payload_in_metadata`. The downstream RBAC filter can then access these claims:

```yaml
- name: envoy.filters.http.rbac
  typed_config:
    "@type": type.googleapis.com/envoy.extensions.filters.http.rbac.v3.RBAC
    rules:
      action: ALLOW
      policies:
        admin_policy:
          permissions:
            - any: true
          principals:
            - metadata:
                filter: envoy.filters.http.jwt_authn
                path:
                  - key: jwt_payload
                  - key: roles
                value:
                  string_match:
                    exact: "admin"
```

## JWKS Cluster

The jwt_authn filter fetches the JWKS (JSON Web Key Set) from the provider to validate token signatures. Define a cluster for this:

```yaml
clusters:
  - name: jwks_cluster
    connect_timeout: 5s
    type: LOGICAL_DNS
    dns_lookup_family: V4_ONLY
    load_assignment:
      cluster_name: jwks_cluster
      endpoints:
        - lb_endpoints:
            - endpoint:
                address:
                  socket_address:
                    address: login.microsoftonline.com
                    port_value: 443
    transport_socket:
      name: envoy.transport_sockets.tls
      typed_config:
        "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.UpstreamTlsContext
        sni: login.microsoftonline.com
```
