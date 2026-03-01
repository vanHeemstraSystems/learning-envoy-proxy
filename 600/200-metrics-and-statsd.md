# Metrics and StatsD

## Envoy's Statistics System

Envoy generates thousands of statistics counters, gauges, and histograms automatically for every component: listeners, clusters, HTTP connections, gRPC calls, circuit breakers, health checks, and more.

## Stats Sinks

Envoy can emit statistics to external systems via **stats sinks** configured in the bootstrap:

```yaml
stats_sinks:
  - name: envoy.stat_sinks.statsd
    typed_config:
      "@type": type.googleapis.com/envoy.config.metrics.v3.StatsdSink
      tcp_cluster_name: statsd_cluster   # Reference a cluster that points to StatsD
      prefix: "envoy"
```

```yaml
stats_sinks:
  - name: envoy.stat_sinks.dog_statsd
    typed_config:
      "@type": type.googleapis.com/envoy.config.metrics.v3.DogStatsdSink
      address:
        socket_address:
          address: 127.0.0.1
          port_value: 8125
      prefix: "envoy"
```

## Stat Prefixes

Each HCM and cluster has a configurable `stat_prefix`. Choose meaningful prefixes to differentiate metrics from multiple listeners:

```yaml
# HCM
stat_prefix: "ingress_http"
# Produces: http.ingress_http.downstream_rq_total

# Cluster
name: "payment_service"
# Produces: cluster.payment_service.upstream_rq_total
```

## Filtering Stats at Collection Time

Reduce cardinality by filtering which stats are emitted:

```yaml
stats_config:
  stats_matcher:
    inclusion_list:
      patterns:
        - safe_regex:
            regex: "cluster\\..*\\.upstream_rq.*"
        - safe_regex:
            regex: "http\\..*\\.downstream_rq.*"
        - exact: "server.live"
```

## Tag Extraction

Envoy can extract tag dimensions from stat names for dimensionality:

```yaml
stats_config:
  use_all_default_tags: true
  stats_tags:
    - tag_name: "cluster_name"
      regex: "^cluster\\.((.+?)\\.)"
```
