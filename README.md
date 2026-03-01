# Learning Envoy Proxy

Based on "Learning Envoy Proxy" at https://github.com/vanHeemstraSystems/learning-envoy-proxy

Envoy Proxy is a high-performance, open-source edge and service proxy designed for cloud-native applications. Originally built at Lyft, it has become the de facto data plane for service meshes (including Istio) and is widely used in platforms such as Azure Kubernetes Service (AKS). This repository provides a systematic, hands-on approach to mastering Envoy Proxy — from core concepts to advanced traffic management and observability integrations.

## Executive Summary

This learning repository covers Envoy Proxy architecture, xDS API, listener/cluster/route configuration, load balancing, observability, security (mTLS, JWT, RBAC), WebAssembly extensions, and integration with Kubernetes and service meshes. Practical YAML/JSON examples and Docker-based labs are provided throughout.

## Table of Contents

- [100 - Introduction to Envoy Proxy](#100---introduction-to-envoy-proxy)
- [200 - Core Architecture](#200---core-architecture)
- [300 - Static Configuration](#300---static-configuration)
- [400 - Dynamic Configuration (xDS API)](#400---dynamic-configuration-xds-api)
- [500 - Traffic Management](#500---traffic-management)
- [600 - Observability](#600---observability)
- [700 - Security](#700---security)
- [800 - Extensions and WebAssembly](#800---extensions-and-webassembly)
- [900 - Best Practices and Atlas IDP Integration](#900---best-practices-and-atlas-idp-integration)

## Directory Structure

```
learning-envoy-proxy/
├── README.md
│
├── 100/                                          # Introduction to Envoy Proxy
│   ├── README.md
│   ├── 100-what-is-envoy.md
│   ├── 200-history-and-ecosystem.md
│   ├── 300-use-cases.md
│   ├── 400-envoy-vs-nginx-vs-haproxy.md
│   └── examples/
│       └── hello-envoy/
│           ├── docker-compose.yml
│           └── envoy.yaml
│
├── 200/                                          # Core Architecture
│   ├── README.md
│   ├── 100-threading-model.md
│   ├── 200-listeners-filters-clusters.md
│   ├── 300-filter-chains.md
│   ├── 400-upstream-downstream.md
│   └── examples/
│       └── architecture-demo/
│           └── envoy.yaml
│
├── 300/                                          # Static Configuration
│   ├── README.md
│   ├── 100-bootstrap-configuration.md
│   ├── 200-listeners.md
│   ├── 300-routes.md
│   ├── 400-clusters.md
│   ├── 500-endpoints.md
│   └── examples/
│       ├── static-proxy/
│       │   ├── docker-compose.yml
│       │   └── envoy.yaml
│       └── http-routing/
│           ├── docker-compose.yml
│           └── envoy.yaml
│
├── 400/                                          # Dynamic Configuration (xDS API)
│   ├── README.md
│   ├── 100-xds-overview.md
│   ├── 200-lds-listener-discovery.md
│   ├── 300-rds-route-discovery.md
│   ├── 400-cds-cluster-discovery.md
│   ├── 500-eds-endpoint-discovery.md
│   ├── 600-sds-secret-discovery.md
│   ├── 700-ads-aggregated-discovery.md
│   └── examples/
│       └── xds-control-plane/
│           ├── docker-compose.yml
│           ├── envoy.yaml
│           └── control-plane/
│               └── server.py
│
├── 500/                                          # Traffic Management
│   ├── README.md
│   ├── 100-load-balancing-algorithms.md
│   ├── 200-health-checking.md
│   ├── 300-retries-and-timeouts.md
│   ├── 400-circuit-breakers.md
│   ├── 500-rate-limiting.md
│   ├── 600-traffic-splitting-canary.md
│   ├── 700-header-manipulation.md
│   └── examples/
│       ├── load-balancing/
│       │   ├── docker-compose.yml
│       │   └── envoy.yaml
│       └── canary-deployment/
│           ├── docker-compose.yml
│           └── envoy.yaml
│
├── 600/                                          # Observability
│   ├── README.md
│   ├── 100-access-logging.md
│   ├── 200-metrics-and-statsd.md
│   ├── 300-prometheus-integration.md
│   ├── 400-distributed-tracing.md
│   ├── 500-zipkin-jaeger.md
│   └── examples/
│       └── observability-stack/
│           ├── docker-compose.yml
│           ├── envoy.yaml
│           └── prometheus.yml
│
├── 700/                                          # Security
│   ├── README.md
│   ├── 100-tls-termination.md
│   ├── 200-mtls-mutual-tls.md
│   ├── 300-jwt-authentication.md
│   ├── 400-rbac-authorization.md
│   ├── 500-external-authorization.md
│   └── examples/
│       ├── mtls/
│       │   ├── certs/
│       │   │   └── generate-certs.sh
│       │   ├── docker-compose.yml
│       │   └── envoy.yaml
│       └── jwt-auth/
│           ├── docker-compose.yml
│           └── envoy.yaml
│
├── 800/                                          # Extensions and WebAssembly
│   ├── README.md
│   ├── 100-http-filters.md
│   ├── 200-network-filters.md
│   ├── 300-wasm-extensions.md
│   ├── 400-lua-filters.md
│   ├── 500-ext-proc-external-processing.md
│   └── examples/
│       ├── lua-filter/
│       │   ├── docker-compose.yml
│       │   └── envoy.yaml
│       └── wasm-filter/
│           ├── docker-compose.yml
│           └── envoy.yaml
│
└── 900/                                          # Best Practices and Atlas IDP Integration
    ├── README.md
    ├── 100-performance-tuning.md
    ├── 200-kubernetes-integration.md
    ├── 300-istio-and-envoy.md
    ├── 400-envoy-on-aks.md
    ├── 500-atlas-idp-patterns.md
    ├── 600-troubleshooting.md
    └── examples/
        ├── kubernetes-sidecar/
        │   ├── deployment.yaml
        │   └── configmap.yaml
        └── aks-ingress/
            ├── ingress.yaml
            └── envoy-config.yaml
```

## Prerequisites

Before working through this repository, ensure you have the following tools installed:

- **Docker** and **Docker Compose** (for running local labs)
- **kubectl** (for Kubernetes examples)
- **curl** and **jq** (for testing and JSON processing)
- **Python 3.x** (for xDS control plane examples)
- Basic understanding of HTTP/HTTPS, TCP/IP, and microservices

## Getting Started

1. Clone this repository: `git clone https://github.com/vanHeemstraSystems/learning-envoyproxy`
2. Navigate to `100/` and read `100-what-is-envoy.md` to build a conceptual foundation.
3. Follow the numbered sections sequentially — each builds on the previous.
4. Run the Docker Compose examples in each `examples/` subdirectory to reinforce theory with practice.

## Learning Path

**Beginner** → Sections 100–300: Understand what Envoy is, how it is architected, and how to write static configurations.

**Intermediate** → Sections 400–600: Master dynamic xDS configuration, advanced traffic management, and observability.

**Advanced** → Sections 700–900: Implement security (mTLS, JWT, RBAC), write extensions, and integrate Envoy with Kubernetes and the Atlas IDP.

## Key Concepts at a Glance

| Concept | Description |
|---|---|
| Listener | Network entry point that accepts connections on a port |
| Filter Chain | Pipeline of filters applied to traffic through a listener |
| Cluster | Group of upstream endpoints Envoy can forward traffic to |
| Route | Rules that map incoming requests to clusters |
| xDS API | Dynamic discovery service APIs (LDS, RDS, CDS, EDS, SDS, ADS) |
| HCM | HTTP Connection Manager — the core HTTP filter in Envoy |
| mTLS | Mutual TLS for service-to-service authentication |
| WASM | WebAssembly for writing portable Envoy extensions |

## Resources

- [Official Envoy Proxy Documentation](https://www.envoyproxy.io/docs)
- [Envoy GitHub Repository](https://github.com/envoyproxy/envoy)
- [Envoy API Reference](https://www.envoyproxy.io/docs/envoy/latest/api/api)
- [Envoy Sandbox Examples](https://www.envoyproxy.io/docs/envoy/latest/start/sandboxes/)
- [Istio and Envoy](https://istio.io/latest/docs/concepts/traffic-management/)
- [CNCF Envoy Project](https://www.cncf.io/projects/envoy/)

## Related Learning Repositories

This repository is part of the Atlas IDP learning series:

- [Learning Backstage](https://github.com/vanHeemstraSystems/learning-backstage)
- [Learning Kubernetes](https://github.com/vanHeemstraSystems/learning-kubernetes)
- [Learning Docker](https://github.com/vanHeemstraSystems/learning-docker)
- [Learning Azure](https://github.com/vanHeemstraSystems/learning-azure)
- [Learning Crossplane](https://github.com/vanHeemstraSystems/learning-crossplane)

## Author

**Willem van Heemstra**  
Cloud Engineer  
[GitHub](https://github.com/vanHeemstraSystems)

## License

MIT License — see [LICENSE](LICENSE) for details.

---

**Last Updated**: February 2026
