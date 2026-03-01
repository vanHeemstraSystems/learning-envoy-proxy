# Task 03-02 — Jaeger Distributed Tracing

> **Story:** [Distributed Tracing](../stories/story-03-02-distributed-tracing.md)  
> **Effort:** ~45 minutes

---

## Objective

Configure Envoy to send distributed traces to Jaeger and view the full request trace including upstream timing.

---

## Step 1: Docker Compose with Jaeger

```yaml
# docker-compose.yml
version: "3.8"
services:
  envoy:
    image: envoyproxy/envoy:v1.29-latest
    volumes:
      - ./envoy-tracing.yaml:/etc/envoy/envoy.yaml
    ports:
      - "10000:10000"
      - "9901:9901"

  jaeger:
    image: jaegertracing/all-in-one:latest
    environment:
      - COLLECTOR_OTLP_ENABLED=true
    ports:
      - "16686:16686"   # Jaeger UI
      - "9411:9411"     # Zipkin-compatible endpoint
      - "4317:4317"     # OTLP gRPC
    
  backend:
    image: kennethreitz/httpbin
```

---

## Step 2: Envoy Configuration with Tracing

```yaml
# envoy-tracing.yaml
static_resources:
  listeners:
    - name: listener_0
      address:
        socket_address: { address: 0.0.0.0, port_value: 10000 }
      filter_chains:
        - filters:
            - name: envoy.filters.network.http_connection_manager
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
                stat_prefix: ingress_http
                generate_request_id: true
                tracing:
                  provider:
                    name: envoy.tracers.zipkin
                    typed_config:
                      "@type": type.googleapis.com/envoy.config.trace.v3.ZipkinConfig
                      collector_cluster: jaeger_cluster
                      collector_endpoint: "/api/v2/spans"
                      collector_endpoint_version: HTTP_JSON
                      trace_id_128bit: true
                      shared_span_context: false
                  random_sampling:
                    value: 100.0   # Sample 100% for learning; reduce in production
                route_config:
                  name: local_route
                  virtual_hosts:
                    - name: local_service
                      domains: ["*"]
                      routes:
                        - match: { prefix: "/" }
                          route:
                            cluster: backend_cluster
                            timeout: 10s
                          decorator:
                            operation: "GET /api"   # Appears as span operation name
                http_filters:
                  - name: envoy.filters.http.router
                    typed_config:
                      "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router

  clusters:
    - name: backend_cluster
      type: STRICT_DNS
      connect_timeout: 5s
      load_assignment:
        cluster_name: backend_cluster
        endpoints:
          - lb_endpoints:
              - endpoint:
                  address:
                    socket_address: { address: backend, port_value: 80 }

    - name: jaeger_cluster
      type: STRICT_DNS
      connect_timeout: 5s
      load_assignment:
        cluster_name: jaeger_cluster
        endpoints:
          - lb_endpoints:
              - endpoint:
                  address:
                    socket_address: { address: jaeger, port_value: 9411 }

admin:
  address:
    socket_address: { address: 0.0.0.0, port_value: 9901 }
```

---

## Step 3: Start and Generate Traces

```bash
docker compose up -d
sleep 5

# Generate requests
for i in {1..20}; do
  curl -s http://localhost:10000/get > /dev/null
  curl -s http://localhost:10000/delay/1 > /dev/null
  curl -s http://localhost:10000/status/404 > /dev/null
done
```

---

## Step 4: View Traces in Jaeger UI

Open http://localhost:16686

1. Select "envoy" from the Service dropdown
2. Click "Find Traces"
3. Click on a trace to see the full span timeline
4. Observe: `egress` span (time in Envoy) + `backend` span (upstream response time)

---

## Step 5: Propagate Headers to Backend

Note the trace headers Envoy adds to upstream requests:

```bash
# Check what headers Envoy adds (httpbin echoes request headers)
curl -s http://localhost:10000/get | jq .headers | grep -i "b3\|x-request\|trace"
```

You should see `X-B3-Traceid`, `X-B3-Spanid`, `X-B3-Sampled`, and `X-Request-Id`.

---

## Verification

- [ ] Jaeger UI at http://localhost:16686 shows traces for service "envoy"
- [ ] Each trace shows timing for Envoy processing and upstream response
- [ ] `/delay/1` traces show ~1000ms duration
- [ ] Trace headers are visible in httpbin's `/get` response
