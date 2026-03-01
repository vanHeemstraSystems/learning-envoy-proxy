# Route Discovery Service (RDS)

## What RDS Manages

RDS pushes **RouteConfiguration** resources to Envoy. Rather than embedding the full route table inside the listener (as in static config), the HCM references a named route config and Envoy fetches it from the RDS server.

## Why RDS?

Route configurations change frequently (new virtual hosts, new path rules, canary traffic splits). RDS allows updating routes independently of listeners, without replacing the entire listener resource.

## HCM Configuration for RDS

```yaml
- name: envoy.filters.network.http_connection_manager
  typed_config:
    "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
    stat_prefix: ingress_http
    rds:
      route_config_name: my_route_config   # Name Envoy will subscribe to via RDS
      config_source:
        resource_api_version: V3
        api_config_source:
          api_type: GRPC
          transport_api_version: V3
          grpc_services:
            - envoy_grpc:
                cluster_name: xds_cluster
    http_filters:
      - name: envoy.filters.http.router
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router
```

## Route Configuration Resource

The RDS server pushes a `RouteConfiguration` proto that Envoy applies without interruption to existing connections.

```json
{
  "name": "my_route_config",
  "virtual_hosts": [
    {
      "name": "backend",
      "domains": ["*"],
      "routes": [
        {
          "match": { "prefix": "/" },
          "route": { "cluster": "my_cluster" }
        }
      ]
    }
  ]
}
```

## Atomic Updates

RDS updates are applied atomically — Envoy switches from old to new route config without a race condition. Requests that started routing before the update complete with the old config; new requests use the new config.
