# Envoy vs NGINX vs HAProxy

## Comparison Matrix

| Feature | Envoy | NGINX | HAProxy |
|---|---|---|---|
| Primary use case | Cloud-native service proxy | Web server + proxy | High-performance TCP/HTTP LB |
| Configuration | YAML/JSON (dynamic via xDS) | Text file (static) | Text file (static) |
| Dynamic config reload | Hot reload via xDS API, no restarts | Reload via signal (brief disruption) | Runtime API (partial) |
| HTTP/2 | Full (both ingress and egress) | Partial (ingress only in open source) | Partial |
| gRPC | Native L7 awareness | Passthrough only | Passthrough only |
| Observability | Built-in metrics, tracing, access logs | Basic access logs; metrics via module | Stats socket |
| Service mesh | First-class sidecar support | Not designed for sidecar | Not designed for sidecar |
| Extensions | WASM, Lua, C++ filters | Lua, C modules | Limited |
| Resource usage | Higher memory baseline | Lower memory baseline | Very low memory baseline |
| Learning curve | Steeper (verbose configuration) | Moderate | Moderate |

## When to Choose Envoy

- You need **dynamic configuration** that changes without restarts (essential for Kubernetes where pods come and go)
- You need **gRPC-aware** load balancing (round-robin is wrong for gRPC; Envoy does least-request natively)
- You are building or operating a **service mesh** (Istio, AWS App Mesh)
- You need **rich observability** built in (Prometheus metrics, Zipkin/Jaeger tracing without plugins)
- You need **fine-grained traffic policies** per route (retries, timeouts, circuit breakers in config, not code)

## When NGINX or HAProxy May Be Simpler

- Static web serving with basic reverse proxy needs
- Very resource-constrained environments where Envoy's memory footprint is a concern
- Teams already deeply familiar with NGINX/HAProxy and not using Kubernetes service meshes

## Conclusion

For Atlas IDP and AKS-based platforms, Envoy (either directly or via Istio/Contour) is the natural choice. Its xDS-based dynamic configuration is essential in environments where upstream endpoints change continuously as pods scale up and down.
