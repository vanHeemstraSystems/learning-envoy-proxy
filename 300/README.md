# 300 - Static Configuration

Static configuration is the foundation of Envoy. Before learning dynamic xDS APIs, you must understand how to express the complete proxy configuration in a single YAML file.

## Contents

| File | Description |
|---|---|
| [100-bootstrap-configuration.md](100-bootstrap-configuration.md) | The top-level bootstrap structure |
| [200-listeners.md](200-listeners.md) | Defining listeners and filter chains |
| [300-routes.md](300-routes.md) | Route tables, virtual hosts, and match conditions |
| [400-clusters.md](400-clusters.md) | Cluster types, discovery, and options |
| [500-endpoints.md](500-endpoints.md) | Endpoints within clusters |

## Labs

- `examples/static-proxy/` — A minimal working HTTP reverse proxy with one listener and one cluster
- `examples/http-routing/` — Multiple virtual hosts and path-based routing to two backend services
