# Routes

## Route Configuration Structure

Routes live inside the HTTP Connection Manager and are organized hierarchically:

```
RouteConfiguration
  └── VirtualHost (matched by Host header)
        └── Route (matched by path/header/query param)
              └── RouteAction (forward to cluster) or DirectResponse or Redirect
```

## Virtual Hosts

A virtual host matches incoming requests by the HTTP `Host:` header (or `:authority` in HTTP/2).

```yaml
virtual_hosts:
  - name: api_vhost
    domains:
      - "api.example.com"
      - "api.example.com:443"
    routes:
      - match:
          prefix: "/v1/"
        route:
          cluster: api_v1_cluster
      - match:
          prefix: "/v2/"
        route:
          cluster: api_v2_cluster

  - name: default_vhost
    domains:
      - "*"   # Catch-all
    routes:
      - match:
          prefix: "/"
        direct_response:
          status: 404
          body:
            inline_string: "Not found"
```

## Route Match Conditions

Routes are evaluated **in order** — the first match wins.

| Match Type | Example |
|---|---|
| Prefix | `prefix: "/api/"` |
| Exact path | `path: "/healthz"` |
| Regex | `safe_regex: { regex: "^/user/[0-9]+$" }` |
| Header match | `headers: [{name: "x-env", exact_match: "staging"}]` |
| Query parameter | `query_parameters: [{name: "version", exact_match: "2"}]` |

## Route Actions

**`route`** — Forward to a cluster (standard proxy behavior).

```yaml
route:
  cluster: my_cluster
  timeout: 15s
  retry_policy:
    retry_on: 5xx,connect-failure
    num_retries: 3
```

**`redirect`** — Issue an HTTP redirect response.

```yaml
redirect:
  https_redirect: true
```

**`direct_response`** — Return a fixed response without hitting any upstream.

```yaml
direct_response:
  status: 200
  body:
    inline_string: '{"status": "ok"}'
```

## Per-Route Configuration

Individual route entries can override cluster-level settings:

```yaml
routes:
  - match:
      prefix: "/slow-endpoint/"
    route:
      cluster: backend
      timeout: 60s          # Override default timeout for this route only
      max_grpc_timeout: 60s
```
