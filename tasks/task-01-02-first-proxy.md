# Task 01-02 — First Proxy

> **Story:** [Listeners, Clusters, Routes](../stories/story-01-03-listener-cluster-route.md)  
> **Effort:** ~30 minutes  
> **Prerequisites:** [Task 01-01 — Install Envoy](task-01-01-install-envoy.md) complete

---

## Objective

Write a minimal Envoy configuration from scratch and use it to proxy HTTP traffic to `httpbin.org`. Observe the request flow through the admin API.

---

## Step 1: Create the Config File

Create a file named `envoy-first-proxy.yaml`:

```yaml
# envoy-first-proxy.yaml
static_resources:
  listeners:
    - name: listener_0
      address:
        socket_address:
          address: 0.0.0.0
          port_value: 10000
      filter_chains:
        - filters:
            - name: envoy.filters.network.http_connection_manager
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
                stat_prefix: ingress_http
                route_config:
                  name: local_route
                  virtual_hosts:
                    - name: local_service
                      domains: ["*"]
                      routes:
                        - match:
                            prefix: "/"
                          route:
                            cluster: httpbin_cluster
                            host_rewrite_literal: "httpbin.org"
                http_filters:
                  - name: envoy.filters.http.router
                    typed_config:
                      "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router

  clusters:
    - name: httpbin_cluster
      connect_timeout: 10s
      type: STRICT_DNS
      lb_policy: ROUND_ROBIN
      load_assignment:
        cluster_name: httpbin_cluster
        endpoints:
          - lb_endpoints:
              - endpoint:
                  address:
                    socket_address:
                      address: httpbin.org
                      port_value: 80

admin:
  address:
    socket_address:
      address: 0.0.0.0
      port_value: 9901
```

---

## Step 2: Run Envoy with Your Config

```bash
docker run -d \
  --name envoy-proxy \
  -p 10000:10000 \
  -p 9901:9901 \
  -v $(pwd)/envoy-first-proxy.yaml:/etc/envoy/envoy.yaml \
  envoyproxy/envoy:v1.29-latest

# Verify it started
docker logs envoy-proxy
```

---

## Step 3: Test the Proxy

```bash
# Should return your IP (proxied via Envoy to httpbin.org)
curl -s http://localhost:10000/ip | jq .

# Should return request headers as seen by httpbin
curl -s http://localhost:10000/get | jq .headers

# Test a POST
curl -s -X POST http://localhost:10000/post \
  -H "Content-Type: application/json" \
  -d '{"test": "envoy proxy"}' | jq .
```

---

## Step 4: Observe via Admin API

```bash
# Verify cluster is healthy
curl -s http://localhost:9901/clusters | grep httpbin

# Check request counters
curl -s "http://localhost:9901/stats?filter=http.ingress_http"

# Prometheus metrics
curl -s http://localhost:9901/stats/prometheus | grep downstream_rq_total
```

---

## Step 5: Add a Second Route

Modify the route config to add a direct response for `/health`:

```yaml
routes:
  - match:
      prefix: "/health"
    direct_response:
      status: 200
      body:
        inline_string: "Envoy is healthy\n"
  - match:
      prefix: "/"
    route:
      cluster: httpbin_cluster
      host_rewrite_literal: "httpbin.org"
```

Restart Envoy and test:

```bash
curl http://localhost:10000/health
# Expected: Envoy is healthy
```

---

## Step 6: Clean Up

```bash
docker stop envoy-proxy && docker rm envoy-proxy
```

---

## Verification

You have successfully completed this task when:
- [ ] `curl http://localhost:10000/ip` returns your IP address (via httpbin.org)
- [ ] Admin stats show `downstream_rq_total` incrementing with each request
- [ ] `/health` returns a direct 200 response without hitting httpbin

---

*Next task: [Task 02-01 — Write Static Config](task-02-01-write-static-config.md)*
