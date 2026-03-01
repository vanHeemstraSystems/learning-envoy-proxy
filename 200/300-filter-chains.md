# Filter Chains

## What Is a Filter Chain?

A **Filter Chain** is a set of network filters (plus optional match criteria) attached to a listener. When a new connection arrives on a listener, Envoy evaluates the filter chain match conditions and selects the appropriate chain to handle the connection.

A listener can have **multiple filter chains** to handle different types of traffic on the same port. For example, a single port can serve both TLS and non-TLS connections with different processing logic.

## Filter Chain Match

Filter chains can be selected based on:

- **Server Name Indication (SNI)** — the TLS server name in the ClientHello
- **Transport protocol** — `tls` or `raw_buffer`
- **Application protocol** — e.g., `h2` or `http/1.1` (negotiated via ALPN)
- **Source/destination IP** — CIDR ranges
- **Destination port**

```yaml
filter_chains:
  - filter_chain_match:
      server_names: ["api.example.com"]
      transport_protocol: "tls"
    filters:
      - name: envoy.filters.network.http_connection_manager
        # ... HCM config for API traffic
  - filter_chain_match:
      server_names: ["admin.example.com"]
      transport_protocol: "tls"
    filters:
      - name: envoy.filters.network.http_connection_manager
        # ... HCM config for admin traffic
```

## HTTP Filter Chain

Within the HCM, HTTP filters form their own ordered chain. Each filter can:

- **Inspect** the request/response headers and body
- **Modify** headers or body
- **Short-circuit** the chain (e.g., reject an unauthenticated request)
- **Pass** the request to the next filter

The **router filter** (`envoy.filters.http.router`) must always be the **last** HTTP filter. It is responsible for forwarding the request to the selected cluster.

## Filter Chain Best Practices

- Order matters: authentication filters before authorization filters before router
- Keep the chain short — every filter adds latency
- Use the `per_filter_config` mechanism on routes to override filter behavior per route without adding a new listener
