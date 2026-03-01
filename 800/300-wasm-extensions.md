# WebAssembly (WASM) Extensions

## What Is WASM in Envoy?

Envoy supports loading **WebAssembly** (WASM) modules as HTTP or network filters. WASM allows you to write filter logic in any language that compiles to WASM (Rust, C++, Go via TinyGo, AssemblyScript) and load it into Envoy at runtime — without recompiling Envoy itself.

## Why WASM?

| Requirement | Lua | WASM | C++ Native |
|---|---|---|---|
| Dynamic loading | Yes | Yes | No (requires rebuild) |
| Language flexibility | Lua only | Many languages | C++ only |
| Performance | Good | Good (near-native) | Best |
| Safety (sandboxed) | Limited | Yes (WASM sandbox) | No |
| Async HTTP calls | No | Yes | Yes |

## WASM Filter Configuration

```yaml
http_filters:
  - name: envoy.filters.http.wasm
    typed_config:
      "@type": type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm
      config:
        name: "my_wasm_filter"
        root_id: "my_root_id"
        vm_config:
          vm_id: "my_vm"
          runtime: "envoy.wasm.runtime.v8"   # V8 JavaScript engine (used for WASM bytecode)
          code:
            local:
              filename: /etc/envoy/filter.wasm
          configuration:
            "@type": type.googleapis.com/google.protobuf.StringValue
            value: '{"key": "value"}'          # Config passed to the WASM module
```

## Rust WASM Example

Using the `proxy-wasm-rust-sdk`:

```rust
use proxy_wasm::traits::*;
use proxy_wasm::types::*;

proxy_wasm::main! {{
    proxy_wasm::set_http_context(|_, _| -> Box<dyn HttpContext> {
        Box::new(MyFilter)
    });
}}

struct MyFilter;

impl HttpContext for MyFilter {
    fn on_http_request_headers(&mut self, _: usize, _: bool) -> Action {
        // Add a custom header
        self.set_http_request_header("x-custom-header", Some("hello-from-wasm"));
        Action::Continue
    }
}
```

Compile: `cargo build --target wasm32-unknown-unknown --release`

## Loading WASM from Remote (Oci/HTTP)

```yaml
vm_config:
  runtime: "envoy.wasm.runtime.v8"
  code:
    remote:
      http_uri:
        uri: "https://my-registry.example.com/my-filter.wasm"
        cluster: wasm_registry_cluster
        timeout: 10s
      sha256: "abc123..."   # Required for integrity verification
```

## Proxy-WASM ABI

The WASM module communicates with Envoy via the **proxy-wasm ABI** (Application Binary Interface) — a set of host functions exposed to the WASM sandbox. These include functions to get/set headers, read/write body buffers, make async HTTP calls to other clusters, and set shared data.
