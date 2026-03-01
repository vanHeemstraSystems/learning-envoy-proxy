# Listeners

## What Is a Listener?

A listener is the entry point for traffic into Envoy. It binds to an IP address and port and accepts connections. Every listener has one or more **filter chains** that process accepted connections.

## Listener Types

**TCP Listener** (most common) — binds a TCP socket.

**UDP Listener** — binds a UDP socket (for protocols like QUIC).

**Pipe Listener** — binds a Unix domain socket (useful for local IPC within a pod).

```yaml
# TCP listener
address:
  socket_address:
    address: 0.0.0.0
    port_value: 10000

# Unix pipe listener
address:
  pipe:
    path: /var/run/envoy.sock
```

## Listener Options

**`use_original_dst`** — When Envoy is configured as a transparent proxy (e.g., iptables redirect), this tells the listener to use the original destination IP/port as the routing target. Essential for sidecar deployments.

**`transparent`** — Enables IP_TRANSPARENT socket option for non-local source IP preservation.

**`freebind`** — Allows binding to an IP that is not yet configured on the interface (useful in some cloud environments).

**`per_connection_buffer_limit_bytes`** — Controls read/write buffer sizes per connection. Reduce this for memory-constrained environments with many connections.

## Listener Filters

Before the filter chain runs, **listener filters** execute. They inspect the raw socket or early bytes of a connection to gather metadata used in filter chain matching.

Common listener filters:

- **`envoy.filters.listener.tls_inspector`** — Reads the TLS ClientHello to extract SNI and ALPN. Required for SNI-based filter chain matching.
- **`envoy.filters.listener.http_inspector`** — Detects if a non-TLS connection is HTTP/1.1 or HTTP/2.
- **`envoy.filters.listener.original_dst`** — Recovers the original destination address from iptables REDIRECT rules.

```yaml
listener_filters:
  - name: envoy.filters.listener.tls_inspector
    typed_config:
      "@type": type.googleapis.com/envoy.extensions.filters.listener.tls_inspector.v3.TlsInspector
```
