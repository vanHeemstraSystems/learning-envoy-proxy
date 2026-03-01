# Flow 02 — Envoy Configuration

## Goal

Master both static bootstrap configuration and the dynamic xDS API that enables Envoy to receive configuration updates at runtime without restarts.

## Why This Matters

The xDS API is what makes Envoy "programmable". Control planes like Istio Pilot, Contour, and Envoy Gateway all speak xDS. Understanding it unlocks the ability to build or integrate custom control planes — a key skill for Atlas IDP platform engineering.

## Stories in This Flow

| # | Story | Effort |
|---|---|---|
| 02-01 | [Static Bootstrap Configuration](../stories/story-02-01-static-config.md) | 45 min |
| 02-02 | [xDS Dynamic Configuration API](../stories/story-02-02-xds-api.md) | 60 min |
| 02-03 | [Control Planes (go-control-plane, Contour)](../stories/story-02-03-control-plane.md) | 45 min |

## Tasks in This Flow

| # | Task | Effort |
|---|---|---|
| 02-01 | [Write Static Config](../tasks/task-02-01-write-static-config.md) | 30 min |
| 02-02 | [xDS Server in Python](../tasks/task-02-02-xds-server-python.md) | 60 min |

## Learning Outcomes

By the end of this flow you will be able to:

- Write a complete Envoy static bootstrap YAML from scratch
- Explain the six xDS resource types: LDS, RDS, CDS, EDS, SDS, RTDS
- Describe how a control plane pushes configuration to Envoy via ADS (Aggregated Discovery Service)
- Implement a minimal gRPC xDS server using the Python `grpc` library
- Identify which control plane is appropriate for a given use case

## Estimated Total Time

~4 hours (reading + hands-on)

---

*Previous: [Flow 01 — Fundamentals](flow-01-fundamentals.md)*  
*Next: [Flow 03 — Observability](flow-03-observability.md)*
