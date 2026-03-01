# 800 - Extensions and WebAssembly

Envoy's filter architecture is extensible. This section covers the built-in extension mechanisms (Lua scripting, WASM modules, and ext_proc) for customizing Envoy behavior without writing C++ or rebuilding the binary.

## Contents

| File | Description |
|---|---|
| [100-http-filters.md](100-http-filters.md) | Overview of built-in HTTP filters |
| [200-network-filters.md](200-network-filters.md) | TCP/UDP network filters |
| [300-wasm-extensions.md](300-wasm-extensions.md) | WebAssembly filter development |
| [400-lua-filters.md](400-lua-filters.md) | Lua scripting for header manipulation |
| [500-ext-proc-external-processing.md](500-ext-proc-external-processing.md) | External processing filter |
