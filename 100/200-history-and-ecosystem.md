# History and Ecosystem

## Origin: Lyft (2015–2016)

Envoy was created by **Matt Klein** and the infrastructure team at **Lyft** to solve the problems they encountered while decomposing their monolithic application into microservices. The key insight was that embedding resiliency logic in each service (via language-specific libraries) was fragile, inconsistent, and invisible.

Lyft open-sourced Envoy in **September 2016**.

## CNCF Graduation (2018)

Envoy was donated to the **Cloud Native Computing Foundation (CNCF)** in September 2017 and **graduated** in November 2018, joining Kubernetes and Prometheus as a top-level CNCF project. This confirmed its production readiness and broad industry adoption.

## Adoption

Envoy is used in production by many large organizations including:

- **Google** — underpins Google Cloud's Traffic Director and is the data plane in Istio
- **AWS** — used in AWS App Mesh
- **Microsoft** — used in Azure Service Fabric Mesh and AKS add-ons
- **Lyft, Airbnb, Pinterest, Stripe** — heavy production users

## The xDS Ecosystem

Envoy introduced the **xDS APIs** (discovery service APIs) which have become an industry standard. Other proxies (like gRPC's built-in xDS support) now implement the same xDS protocol, meaning a control plane built for Envoy can also configure other data planes.

## Envoy in the Service Mesh Landscape

| Service Mesh | Data Plane |
|---|---|
| Istio | Envoy (via Envoy sidecar injected by istiod) |
| AWS App Mesh | Envoy |
| Consul Connect | Envoy (optional) |
| Linkerd | Linkerd-proxy (Rust, not Envoy) |

Understanding Envoy directly gives you insight into how Istio works under the hood, which is highly relevant for Kubernetes-based platforms.
