# Flow 03 — Observability

## Goal

Configure Envoy's built-in observability capabilities — Prometheus metrics, distributed tracing, and structured access logging — to gain full visibility into proxy traffic.

## Why This Matters

Observability is a first-class concern in the Atlas IDP platform. Envoy emits rich telemetry out of the box, but it must be correctly configured and integrated with your monitoring stack (Prometheus, Grafana, Jaeger/Tempo).

## Stories in This Flow

| # | Story | Effort |
|---|---|---|
| 03-01 | [Prometheus Metrics & Admin API](../stories/story-03-01-prometheus-metrics.md) | 45 min |
| 03-02 | [Distributed Tracing with Jaeger/Zipkin](../stories/story-03-02-distributed-tracing.md) | 45 min |
| 03-03 | [Structured Access Logging](../stories/story-03-03-access-logging.md) | 30 min |

## Tasks in This Flow

| # | Task | Effort |
|---|---|---|
| 03-01 | [Prometheus + Grafana Stack](../tasks/task-03-01-prometheus-grafana.md) | 45 min |
| 03-02 | [Jaeger Tracing Integration](../tasks/task-03-02-jaeger-tracing.md) | 45 min |

## Learning Outcomes

By the end of this flow you will be able to:

- Access the Envoy admin API and interpret key stat categories (http, cluster, listener)
- Configure the Prometheus stats sink and scrape Envoy metrics
- Build a Grafana dashboard with Envoy's golden signals (latency, traffic, errors, saturation)
- Enable distributed tracing with Jaeger using the Zipkin-compatible tracer
- Configure structured JSON access logs and ship them to a log aggregator
- Correlate traces with logs using `x-request-id`

## Estimated Total Time

~3.5 hours (reading + hands-on)

---

*Previous: [Flow 02 — Configuration](flow-02-configuration.md)*  
*Next: [Flow 04 — Kubernetes](flow-04-kubernetes.md)*
