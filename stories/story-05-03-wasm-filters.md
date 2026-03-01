# Story 05-03 — WASM Filters for Custom Logic

> **Flow:** [Advanced](../flows/flow-05-advanced.md)  
> **Effort:** ~60 minutes

---

## What is Proxy-Wasm?

**WebAssembly (WASM)** allows you to compile code written in Rust, Go, C++, or AssemblyScript into a portable binary that runs inside Envoy's filter chain. This enables custom request/response processing without modifying Envoy's source code or rebuilding it.

The [Proxy-Wasm ABI](https://github.com/proxy-wasm/spec) is the specification for the interface between Envoy and WASM modules. It is also supported by NGINX and other proxies.

---

## Use Cases for WASM Filters

- **Custom header manipulation** — add, remove, or transform headers based on business logic
- **Request body inspection** — parse and validate JSON/Protobuf payloads
- **Custom authentication** — integrate with proprietary auth systems
- **Rate limiting** — custom rate limit logic beyond Envoy's built-in filters
- **Data masking** — redact sensitive fields from logs or responses
- **A/B testing logic** — complex routing decisions based on user attributes

---

## Writing a WASM Filter in Rust

```toml
# Cargo.toml
[package]
name = "add-header-filter"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib"]

[dependencies]
proxy-wasm = "0.2"
log = "0.4"
```

```rust
// src/lib.rs
use proxy_wasm::traits::*;
use proxy_wasm::types::*;

proxy_wasm::main! {{
    proxy_wasm::set_log_level(LogLevel::Trace);
    proxy_wasm::set_http_context(|context_id, _| -> Box<dyn HttpContext> {
        Box::new(AddHeaderFilter { context_id })
    });
}}

struct AddHeaderFilter {
    context_id: u32,
}

impl Context for AddHeaderFilter {}

impl HttpContext for AddHeaderFilter {
    fn on_http_request_headers(&mut self, _: usize, _: bool) -> Action {
        // Add a custom header to every request
        self.set_http_request_header("x-atlas-idp", Some("envoy-wasm-v1"));
        Action::Continue
    }

    fn on_http_response_headers(&mut self, _: usize, _: bool) -> Action {
        // Remove a sensitive header from responses
        self.set_http_response_header("x-powered-by", None);
        Action::Continue
    }
}
```

```bash
# Build the WASM module
rustup target add wasm32-wasi
cargo build --target wasm32-wasi --release
# Output: target/wasm32-wasi/release/add_header_filter.wasm
```

---

## Loading WASM in Envoy Configuration

```yaml
http_filters:
  - name: envoy.filters.http.wasm
    typed_config:
      "@type": type.googleapis.com/udpa.type.v1.TypedStruct
      type_url: type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm
      value:
        config:
          name: add_header_filter
          root_id: add_header_filter
          vm_config:
            runtime: envoy.wasm.runtime.v8
            code:
              local:
                filename: /etc/envoy/wasm/add_header_filter.wasm
            allow_precompiled: false
          configuration:
            "@type": type.googleapis.com/google.protobuf.StringValue
            value: '{"custom_header_value": "atlas-idp"}'   # JSON config passed to plugin

  - name: envoy.filters.http.router
    typed_config:
      "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router
```

---

## WASM in Kubernetes via ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: wasm-filter
  namespace: atlas
binaryData:
  add-header-filter.wasm: |
    <base64-encoded .wasm binary>
```

```yaml
# Mount in Envoy sidecar
volumeMounts:
  - name: wasm-filter
    mountPath: /etc/envoy/wasm
volumes:
  - name: wasm-filter
    configMap:
      name: wasm-filter
```

---

## Using Envoy Gateway's EnvoyExtensionPolicy

```yaml
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: EnvoyExtensionPolicy
metadata:
  name: atlas-wasm-policy
spec:
  targetRef:
    group: gateway.networking.k8s.io
    kind: HTTPRoute
    name: my-service-route
  wasm:
    - name: add-header-filter
      code:
        type: Image
        image:
          url: ghcr.io/vanheemstrasystems/add-header-filter:v1.0.0
      config: |
        {"custom_header_value": "atlas-idp"}
```

---

## Performance Considerations

| Aspect | Guidance |
|---|---|
| Startup overhead | WASM modules add ~1-5ms on first request (JIT compilation) |
| Per-request overhead | Typically <1ms for simple filters |
| Memory isolation | Each WASM VM is isolated — bugs don't crash Envoy |
| Hot reload | Supported via xDS; no Envoy restart needed |
| Debugging | Use `proxy_wasm::log!` for logging; inspect via admin API |

---

## Summary

WASM filters allow you to extend Envoy with custom business logic in a safe, sandboxed environment. For Atlas IDP, WASM filters are ideal for organization-specific policies (custom auth, header manipulation, data governance) that don't fit into Envoy's built-in filters.

---

## Knowledge Check

1. What is the Proxy-Wasm specification and why is it important?
2. Which programming languages can you use to write Envoy WASM filters?
3. What are three use cases for WASM filters in an IDP platform?
4. How does Envoy Gateway's `EnvoyExtensionPolicy` simplify WASM filter deployment?
