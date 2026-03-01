# Header Manipulation

## Request Header Manipulation

Add, remove, or modify HTTP request headers before forwarding to the upstream cluster. Configured at the virtual host, route, or weighted cluster level.

```yaml
virtual_hosts:
  - name: my_service
    domains: ["*"]
    request_headers_to_add:
      - header:
          key: "x-forwarded-for-original"
          value: "%DOWNSTREAM_REMOTE_ADDRESS%"
        keep_empty_value: false
    request_headers_to_remove:
      - "x-internal-debug"
    routes:
      - match:
          prefix: "/api/"
        request_headers_to_add:
          - header:
              key: "x-route-context"
              value: "api_route"
        route:
          cluster: my_cluster
```

## Response Header Manipulation

```yaml
routes:
  - match:
      prefix: "/"
    response_headers_to_add:
      - header:
          key: "x-proxy"
          value: "envoy"
      - header:
          key: "cache-control"
          value: "no-store"
    response_headers_to_remove:
      - "server"
      - "x-powered-by"
    route:
      cluster: my_cluster
```

## Dynamic Header Values

Envoy supports **command operators** (format strings) in header values:

| Operator | Value |
|---|---|
| `%DOWNSTREAM_REMOTE_ADDRESS%` | Client IP and port |
| `%REQ(header-name)%` | Value of a request header |
| `%RESP(header-name)%` | Value of a response header |
| `%START_TIME%` | Request start time |
| `%DURATION%` | Total request duration (response headers only) |
| `%UPSTREAM_REMOTE_ADDRESS%` | Upstream endpoint IP and port |
| `%PROTOCOL%` | HTTP/1.1 or HTTP/2 |

Example: add the upstream response time to a response header:

```yaml
response_headers_to_add:
  - header:
      key: "x-upstream-response-time"
      value: "%RESP(x-upstream-duration)%"
```
