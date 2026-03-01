# Use Cases

## 1. Edge / Ingress Proxy

Envoy acts as the front door to your infrastructure — the first point of contact for external clients. In this role it provides:

- TLS termination
- HTTP routing based on host headers or URL paths
- Rate limiting and authentication enforcement
- WebSocket and gRPC passthrough

**Kubernetes equivalent**: Envoy is the engine behind ingress controllers such as **Contour** and the ambassador pattern. Azure's Application Gateway Ingress Controller (AGIC) uses similar concepts.

## 2. Sidecar Proxy (Service Mesh)

In a Kubernetes pod, a second container running Envoy intercepts all network traffic using iptables rules. The application container never talks directly to the network — all traffic flows through Envoy.

Benefits:
- mTLS between every service pair with zero application code changes
- Automatic retries, timeouts, and circuit breaking per route
- Distributed traces emitted without instrumenting application code
- Traffic shifting for canary deployments at the infrastructure level

## 3. API Gateway

Envoy can be configured as a full API gateway with:

- JWT validation (via the JWT authn filter)
- External authorization (calling an OPA or custom service)
- Request/response transformation (via Lua or WASM filters)
- Routing to multiple backend versions based on headers

## 4. Internal Load Balancer

Envoy can serve as a smart internal load balancer for gRPC services, applying:

- Least-request load balancing (unlike round-robin, which is ineffective for long-lived gRPC streams)
- Health-check-aware routing
- Outlier detection (removing bad endpoints automatically)

## 5. Atlas IDP Context

In the Atlas IDP, Envoy is relevant as:

- The data plane of any service mesh layer on AKS
- An ingress controller component (Contour uses Envoy)
- A traffic management layer for platform services exposed to developer teams
