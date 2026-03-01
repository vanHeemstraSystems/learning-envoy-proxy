# External Authorization (ext_authz)

## What Is External Authorization?

The **ext_authz filter** delegates authorization decisions to an external service via gRPC or HTTP. Instead of encoding authorization logic in Envoy configuration (as with the RBAC filter), you call a dedicated authorization service — such as Open Policy Agent (OPA) — that evaluates the full request context against complex policies.

## When to Use ext_authz vs RBAC Filter

Use **RBAC filter** for: simple header/IP/JWT claim matching that can be expressed in config YAML.

Use **ext_authz** for: complex multi-attribute policies, policies that require database lookups, OPA Rego policies, or any logic too complex for YAML expressions.

## ext_authz Configuration (gRPC)

```yaml
http_filters:
  - name: envoy.filters.http.ext_authz
    typed_config:
      "@type": type.googleapis.com/envoy.extensions.filters.http.ext_authz.v3.ExtAuthz
      grpc_service:
        envoy_grpc:
          cluster_name: opa_cluster
        timeout: 0.5s
      transport_api_version: V3
      include_peer_certificate: true   # Forward mTLS cert info to authz service
      with_request_body:
        max_request_bytes: 8192        # Forward up to 8KB of request body
        allow_partial_message: true
      failure_mode_allow: false        # Deny all if authz service is unreachable
```

## What Envoy Sends to the Authz Service

Envoy sends a `CheckRequest` proto containing:

- HTTP request headers and body (up to configured limit)
- Source and destination IP and port
- Connection metadata (mTLS certificate information if `include_peer_certificate: true`)

## What the Authz Service Returns

**Allow**: Return `CheckResponse` with `OkHttpResponse`. Can include additional headers to add to the upstream request.

**Deny**: Return `CheckResponse` with `DeniedHttpResponse` containing the HTTP status code and response body to return to the client (e.g., `403 Forbidden`).

## OPA Integration Example

With OPA running as a gRPC server (using the Envoy plugin):

```yaml
clusters:
  - name: opa_cluster
    connect_timeout: 0.25s
    type: STRICT_DNS
    load_assignment:
      cluster_name: opa_cluster
      endpoints:
        - lb_endpoints:
            - endpoint:
                address:
                  socket_address:
                    address: opa.default.svc.cluster.local
                    port_value: 9191   # OPA gRPC port
    http2_protocol_options: {}         # OPA ext_authz uses gRPC (HTTP/2)
```

OPA Rego policy example:

```rego
package envoy.authz

import future.keywords.if

default allow := false

allow if {
  input.parsed_path[0] == "api"
  input.parsed_path[1] == "public"
}

allow if {
  input.attributes.request.http.headers["authorization"] != ""
  valid_token
}

valid_token if {
  [_, payload, _] := io.jwt.decode(bearer_token)
  payload.iss == "https://sts.windows.net/my-tenant/"
}

bearer_token := t if {
  v := input.attributes.request.http.headers["authorization"]
  startswith(v, "Bearer ")
  t := substring(v, count("Bearer "), -1)
}
```
