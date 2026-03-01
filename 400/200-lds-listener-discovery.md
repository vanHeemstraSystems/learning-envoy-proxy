# Listener Discovery Service (LDS)

## What LDS Manages

LDS pushes complete **Listener** configurations to Envoy. When Envoy receives a new LDS response, it creates, updates, or removes listeners dynamically.

## Envoy Configuration for LDS

Point Envoy to an LDS server in the bootstrap's `dynamic_resources`:

```yaml
dynamic_resources:
  lds_config:
    resource_api_version: V3
    api_config_source:
      api_type: GRPC
      transport_api_version: V3
      grpc_services:
        - envoy_grpc:
            cluster_name: xds_cluster
```

The `xds_cluster` is defined in `static_resources.clusters` — Envoy needs a static way to reach the control plane.

## LDS Lifecycle

1. Envoy connects to the LDS server and sends a `DiscoveryRequest` with its current listener version (empty at startup).
2. The control plane responds with a `DiscoveryResponse` containing all listener resources.
3. Envoy ACKs the response with the new version nonce.
4. When a listener changes, the control plane sends an updated response.
5. Envoy hot-reloads the listener — existing connections are drained, new connections use the updated listener.

## Listener Draining

When a listener is updated or removed via LDS, Envoy **drains** existing connections gracefully:

1. New connections to the old listener are blocked.
2. In-flight requests complete.
3. After the drain timeout, remaining connections are closed.

The drain timeout is configured via `--drain-time-s` CLI flag (default: 600 seconds).
