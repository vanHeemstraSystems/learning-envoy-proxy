# What Is Envoy Proxy?

## Definition

Envoy is a self-contained, high-performance proxy written in C++ designed for cloud-native architectures. It operates as an **L3/L4 (TCP/UDP) and L7 (HTTP/gRPC/HTTP2) proxy**, meaning it can handle both raw network traffic and application-layer protocols intelligently.

It was designed with one guiding philosophy: **the network should be transparent to applications**. When things go wrong, it should be easy to determine the source of the problem.

## What Envoy Does

Envoy sits between services and mediates all inbound and outbound traffic. It provides:

- **Service discovery** — finds upstream services dynamically
- **Load balancing** — distributes traffic across healthy endpoints
- **TLS termination** — offloads encryption from application services
- **HTTP/2 and gRPC proxying** — native support for modern protocols
- **Circuit breaking** — prevents cascading failures
- **Health checking** — actively monitors upstream health
- **Observability** — emits metrics, traces, and logs without application changes
- **Rate limiting** — protects services from overload

## Deployment Models

Envoy is deployed in two primary patterns:

**Edge/Ingress Proxy** — a single Envoy instance at the boundary of a network receives external traffic and routes it to internal services. This is analogous to an API Gateway.

**Sidecar Proxy** — an Envoy instance runs alongside each service instance (as a container sidecar in Kubernetes). All traffic to/from the service flows through its local Envoy. This is the foundation of a service mesh like Istio.

## Why Envoy Over a Library?

Traditionally, resiliency features (retries, circuit breaking, timeouts) were implemented as language-specific libraries embedded in each service. Envoy moves this logic out of the application into the infrastructure layer, making it:

- **Language-agnostic** — any service benefits regardless of implementation language
- **Centrally observable** — metrics and traces come from one place
- **Consistently enforced** — policy is applied uniformly across all services

## Summary

Envoy is the backbone of modern cloud-native traffic management. Understanding it is essential for working with Kubernetes ingress controllers, Istio, and platforms like the Atlas IDP that rely on it for service-to-service communication.
