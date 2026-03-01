# HTTP Filters

## What Are HTTP Filters?

HTTP filters are the processing units within Envoy's HTTP Connection Manager. They form a chain where each filter can inspect and modify the request and response. The chain processes filters in order for every HTTP request.

## Filter Types

**Decoder filters** — process the request (from client to upstream).

**Encoder filters** — process the response (from upstream to client).

**Encoder-Decoder filters** — process both directions.

## Built-in HTTP Filters Reference

| Filter Name | Purpose |
|---|---|
| `envoy.filters.http.router` | Required final filter; routes to cluster |
| `envoy.filters.http.jwt_authn` | JWT token validation |
| `envoy.filters.http.rbac` | Role-Based Access Control |
| `envoy.filters.http.ext_authz` | External authorization service |
| `envoy.filters.http.ratelimit` | Rate limiting (requires global rate limit server) |
| `envoy.filters.http.local_ratelimit` | Per-Envoy rate limiting (no external service) |
| `envoy.filters.http.cors` | CORS header handling |
| `envoy.filters.http.gzip` | Gzip compression |
| `envoy.filters.http.grpc_json_transcoder` | Transcode gRPC ↔ JSON/REST |
| `envoy.filters.http.grpc_web` | gRPC-Web protocol support |
| `envoy.filters.http.health_check` | Return 200 for health probe paths without hitting upstream |
| `envoy.filters.http.lua` | Lua scripting |
| `envoy.filters.http.wasm` | WebAssembly extensions |
| `envoy.filters.http.ext_proc` | External processing service |
| `envoy.filters.http.buffer` | Buffer full request body before passing downstream |
| `envoy.filters.http.csrf` | CSRF protection |
| `envoy.filters.http.fault` | Fault injection (for testing resilience) |

## Filter Ordering Best Practice

```yaml
http_filters:
  # 1. Rate limiting (fail fast, cheapest rejection)
  - name: envoy.filters.http.local_ratelimit
    ...

  # 2. Authentication (verify identity)
  - name: envoy.filters.http.jwt_authn
    ...

  # 3. Authorization (check permissions)
  - name: envoy.filters.http.rbac
    ...

  # 4. Observability / transformation
  - name: envoy.filters.http.lua
    ...

  # 5. Router (always last)
  - name: envoy.filters.http.router
    ...
```

## Fault Injection (Testing)

Use the fault filter to inject artificial delays or errors for resilience testing:

```yaml
- name: envoy.filters.http.fault
  typed_config:
    "@type": type.googleapis.com/envoy.extensions.filters.http.fault.v3.HTTPFault
    abort:
      http_status: 503
      percentage:
        numerator: 10
        denominator: HUNDRED    # 10% of requests get a 503
    delay:
      fixed_delay: 2s
      percentage:
        numerator: 5
        denominator: HUNDRED    # 5% of requests get a 2-second delay
```

Only activate fault injection via runtime feature flags or in dedicated test namespaces.
