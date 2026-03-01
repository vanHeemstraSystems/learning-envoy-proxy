# Task 02-01 — Write a Complete Static Configuration

> **Story:** [Static Bootstrap Configuration](../stories/story-02-01-static-config.md)  
> **Effort:** ~30 minutes

---

## Objective

Write a complete, production-quality Envoy static configuration that includes TLS termination, health checks, circuit breakers, structured access logging, and the Prometheus stats endpoint.

---

## Step 1: Generate a Self-Signed Certificate

```bash
mkdir -p certs

openssl req -x509 -newkey rsa:4096 -keyout certs/server.key \
  -out certs/server.crt -days 365 -nodes \
  -subj "/CN=localhost/O=Atlas IDP Dev"
```

---

## Step 2: Write the Configuration

Create `envoy-production.yaml`:

```yaml
node:
  id: atlas-edge-proxy
  cluster: edge-proxies
  metadata:
    environment: development

admin:
  address:
    socket_address:
      address: 127.0.0.1   # Do not expose admin externally in production
      port_value: 9901

static_resources:
  listeners:
    # HTTP listener — redirect to HTTPS
    - name: http_listener
      address:
        socket_address:
          address: 0.0.0.0
          port_value: 8080
      filter_chains:
        - filters:
            - name: envoy.filters.network.http_connection_manager
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
                stat_prefix: http_redirect
                route_config:
                  virtual_hosts:
                    - name: redirect
                      domains: ["*"]
                      routes:
                        - match: { prefix: "/" }
                          redirect:
                            https_redirect: true
                            port_redirect: 8443
                http_filters:
                  - name: envoy.filters.http.router
                    typed_config:
                      "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router

    # HTTPS listener
    - name: https_listener
      address:
        socket_address:
          address: 0.0.0.0
          port_value: 8443
      filter_chains:
        - transport_socket:
            name: envoy.transport_sockets.tls
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.DownstreamTlsContext
              common_tls_context:
                tls_certificates:
                  - certificate_chain:
                      filename: /etc/certs/server.crt
                    private_key:
                      filename: /etc/certs/server.key
                tls_params:
                  tls_minimum_protocol_version: TLSv1_2
          filters:
            - name: envoy.filters.network.http_connection_manager
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
                stat_prefix: ingress_https
                use_remote_address: true
                access_log:
                  - name: envoy.access_loggers.stdout
                    typed_config:
                      "@type": type.googleapis.com/envoy.extensions.access_loggers.stream.v3.StdoutAccessLog
                      log_format:
                        json_format:
                          timestamp: "%START_TIME%"
                          method: "%REQ(:METHOD)%"
                          path: "%REQ(:PATH)%"
                          protocol: "%PROTOCOL%"
                          response_code: "%RESPONSE_CODE%"
                          response_flags: "%RESPONSE_FLAGS%"
                          duration_ms: "%DURATION%"
                          upstream_host: "%UPSTREAM_HOST%"
                          request_id: "%REQ(X-REQUEST-ID)%"
                route_config:
                  name: https_routes
                  virtual_hosts:
                    - name: api
                      domains: ["*"]
                      routes:
                        - match:
                            prefix: "/health"
                          direct_response:
                            status: 200
                            body:
                              inline_string: "OK\n"
                        - match:
                            prefix: "/"
                          route:
                            cluster: backend_cluster
                            timeout: 30s
                            retry_policy:
                              retry_on: "5xx,gateway-error,connect-failure"
                              num_retries: 3
                              per_try_timeout: 10s
                http_filters:
                  - name: envoy.filters.http.router
                    typed_config:
                      "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router

  clusters:
    - name: backend_cluster
      connect_timeout: 5s
      type: STRICT_DNS
      lb_policy: LEAST_REQUEST
      respect_dns_ttl: true
      health_checks:
        - timeout: 3s
          interval: 15s
          unhealthy_threshold: 3
          healthy_threshold: 2
          http_health_check:
            path: "/health"
      circuit_breakers:
        thresholds:
          - priority: DEFAULT
            max_connections: 512
            max_pending_requests: 512
            max_requests: 1024
            max_retries: 10
      load_assignment:
        cluster_name: backend_cluster
        endpoints:
          - lb_endpoints:
              - endpoint:
                  address:
                    socket_address:
                      address: httpbin.org
                      port_value: 80
```

---

## Step 3: Run Envoy

```bash
docker run -d \
  --name envoy-production \
  -p 8080:8080 \
  -p 8443:8443 \
  -p 9901:9901 \
  -v $(pwd)/envoy-production.yaml:/etc/envoy/envoy.yaml \
  -v $(pwd)/certs:/etc/certs \
  --add-host=host.docker.internal:host-gateway \
  envoyproxy/envoy:v1.29-latest
```

---

## Step 4: Test

```bash
# Health check (direct response, no backend)
curl http://localhost:8080/health

# HTTPS request (self-signed cert, use -k to skip verification)
curl -k https://localhost:8443/ip

# HTTP → HTTPS redirect
curl -v http://localhost:8080/ip
# Expect: 301 redirect to https://localhost:8443/ip

# Verify JSON access log
docker logs envoy-production | jq .
```

---

## Step 5: Verify Circuit Breakers

```bash
# Check circuit breaker stats
curl -s "http://localhost:9901/stats?filter=circuit_breakers"
```

---

## Clean Up

```bash
docker stop envoy-production && docker rm envoy-production
```

---

## Verification

- [ ] HTTP to HTTPS redirect works
- [ ] HTTPS proxies to httpbin.org
- [ ] Access logs appear in JSON format
- [ ] Health check returns 200 without hitting backend
- [ ] Circuit breaker stats visible in admin API
