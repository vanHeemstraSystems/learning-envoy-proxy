# Network Filters

## What Are Network Filters?

Network filters operate at L3/L4, processing raw TCP/UDP byte streams. They sit between the listener and the HTTP Connection Manager (which is itself a network filter).

## Common Network Filters

### HTTP Connection Manager (HCM)

The most important network filter. It upgrades a TCP connection to an HTTP-aware proxy and hosts the HTTP filter chain.

```yaml
- name: envoy.filters.network.http_connection_manager
  typed_config:
    "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
    # ...
```

### TCP Proxy

For pure TCP proxying (non-HTTP protocols like databases, Redis, custom protocols):

```yaml
- name: envoy.filters.network.tcp_proxy
  typed_config:
    "@type": type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy
    stat_prefix: tcp_proxy
    cluster: redis_cluster
    access_log:
      - name: envoy.access_loggers.stdout
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.access_loggers.stream.v3.StdoutAccessLog
```

### MongoDB Proxy

L7-aware MongoDB filter that parses MongoDB wire protocol:

```yaml
- name: envoy.filters.network.mongo_proxy
  typed_config:
    "@type": type.googleapis.com/envoy.extensions.filters.network.mongo_proxy.v3.MongoProxy
    stat_prefix: mongo
    access_log: /dev/stdout
```

Produces per-collection, per-operation metrics.

### Redis Proxy

L7-aware Redis filter supporting cluster topology, read/write splitting, and prefix routing:

```yaml
- name: envoy.filters.network.redis_proxy
  typed_config:
    "@type": type.googleapis.com/envoy.extensions.filters.network.redis_proxy.v3.RedisProxy
    stat_prefix: redis
    settings:
      op_timeout: 5s
    prefix_routes:
      catch_all_route:
        cluster: redis_cluster
```

### MySQL Proxy (experimental)

Parses MySQL wire protocol for L7 MySQL-aware proxying and observability.

### Network-Level ext_authz

Apply external authorization at the TCP level (before HTTP parsing):

```yaml
- name: envoy.filters.network.ext_authz
  typed_config:
    "@type": type.googleapis.com/envoy.extensions.filters.network.ext_authz.v3.ExtAuthz
    grpc_service:
      envoy_grpc:
        cluster_name: authz_cluster
    stat_prefix: ext_authz
    failure_mode_allow: false
```
