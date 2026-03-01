# Story 05-02 — JWT Authentication & RBAC

> **Flow:** [Advanced](../flows/flow-05-advanced.md)  
> **Effort:** ~60 minutes  
> **Task:** [Task 05-01 — JWT Filter](../tasks/task-05-01-jwt-filter.md)

---

## Why JWT at the Proxy Layer?

Validating JWTs at the Envoy proxy layer provides:
- **Centralized enforcement** — no per-service auth code
- **Early rejection** — invalid tokens never reach upstream services
- **Zero application changes** — transparent to backends
- **Correlation with RBAC** — extracted claims drive authorization policies

For Atlas IDP, integrating with **Azure AD (Entra ID)** as the identity provider is the target pattern.

---

## JWT Authentication Filter (`jwt_authn`)

```yaml
http_filters:
  - name: envoy.filters.http.jwt_authn
    typed_config:
      "@type": type.googleapis.com/envoy.extensions.filters.http.jwt_authn.v3.JwtAuthentication
      providers:
        azure_ad:
          issuer: "https://login.microsoftonline.com/{tenant-id}/v2.0"
          audiences:
            - "api://atlas-idp-api"        # Your Azure AD App Registration client ID
          jwks_uri: "https://login.microsoftonline.com/{tenant-id}/discovery/v2.0/keys"
          forward: true                     # Forward JWT to upstream as Authorization header
          forward_payload_header: "x-jwt-payload"  # Forward decoded claims as base64 header
          remote_jwks:
            http_uri:
              uri: "https://login.microsoftonline.com/{tenant-id}/discovery/v2.0/keys"
              cluster: azure_ad_jwks_cluster
              timeout: 5s
            cache_duration:
              seconds: 600               # Cache JWKS for 10 minutes
      rules:
        - match:
            prefix: "/api"
          requires:
            provider_name: "azure_ad"
        - match:
            prefix: "/health"
          requires:
            allow_missing: {}            # No auth required for health endpoint

  - name: envoy.filters.http.router
    typed_config:
      "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router
```

---

## JWKS Cluster

Envoy needs to fetch the JSON Web Key Set (JWKS) from Azure AD to validate token signatures:

```yaml
clusters:
  - name: azure_ad_jwks_cluster
    type: STRICT_DNS
    connect_timeout: 10s
    load_assignment:
      cluster_name: azure_ad_jwks_cluster
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

---

## RBAC Filter

After JWT validation, use extracted claims for role-based access control:

```yaml
http_filters:
  - name: envoy.filters.http.rbac
    typed_config:
      "@type": type.googleapis.com/envoy.extensions.filters.http.rbac.v3.RBAC
      rules:
        action: ALLOW
        policies:
          "admin-access":
            principals:
              - metadata:
                  filter: envoy.filters.http.jwt_authn
                  path:
                    - key: azure_ad
                    - key: roles
                  value:
                    list_match:
                      one_of:
                        string_match:
                          exact: "Atlas.Admin"
            permissions:
              - any: true
          "read-only-access":
            principals:
              - metadata:
                  filter: envoy.filters.http.jwt_authn
                  path:
                    - key: azure_ad
                    - key: roles
                  value:
                    list_match:
                      one_of:
                        string_match:
                          exact: "Atlas.Reader"
            permissions:
              - header:
                  name: ":method"
                  exact_match: "GET"
```

---

## Using Envoy Gateway's SecurityPolicy

With Envoy Gateway, you don't write raw filter config — use the `SecurityPolicy` CRD:

```yaml
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: SecurityPolicy
metadata:
  name: atlas-jwt-policy
spec:
  targetRef:
    group: gateway.networking.k8s.io
    kind: HTTPRoute
    name: my-service-route
  jwt:
    providers:
      - name: azure-ad
        issuer: "https://login.microsoftonline.com/{tenant-id}/v2.0"
        audiences:
          - "api://atlas-idp-api"
        remoteJWKS:
          uri: "https://login.microsoftonline.com/{tenant-id}/discovery/v2.0/keys"
        claimToHeaders:
          - claim: preferred_username
            header: x-user-email
          - claim: roles
            header: x-user-roles
```

---

## Testing JWT Validation

```bash
# Get a token from Azure AD
TOKEN=$(curl -s -X POST \
  "https://login.microsoftonline.com/{tenant-id}/oauth2/v2.0/token" \
  -d "grant_type=client_credentials" \
  -d "client_id={client-id}" \
  -d "client_secret={client-secret}" \
  -d "scope=api://atlas-idp-api/.default" \
  | jq -r '.access_token')

# Call the API with the token
curl -H "Authorization: Bearer $TOKEN" https://atlas.example.com/api/resource

# Call without token (should return 401)
curl https://atlas.example.com/api/resource
```

---

## Summary

Envoy's `jwt_authn` filter validates JWTs at the proxy layer — before traffic reaches your services. Combined with Azure AD as the identity provider and the `rbac` filter for claim-based authorization, you get a robust zero-trust security layer for Atlas IDP without any application code changes.

---

## Knowledge Check

1. What is a JWKS and why does Envoy need to fetch it?
2. Why cache the JWKS and what happens if the cache expires?
3. How does the RBAC filter use data from the JWT filter?
4. What Envoy Gateway CRD replaces manual JWT filter configuration?
