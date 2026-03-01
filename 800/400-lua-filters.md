# Lua Filters

## What Are Lua Filters?

The Lua HTTP filter (`envoy.filters.http.lua`) allows you to write lightweight request and response processing logic in **Lua** without compiling a C++ filter or a WASM module. Lua scripts run synchronously in the filter chain on the worker thread.

## Use Cases

- Add, remove, or modify request/response headers
- Log specific request attributes
- Simple request transformation (e.g., normalize paths, add correlation IDs)
- Early termination with a synthetic response

**Do not use Lua for**: blocking I/O, complex business logic, or anything performance-critical. For complex logic, use the ext_authz filter or a WASM module.

## Configuration

```yaml
http_filters:
  - name: envoy.filters.http.lua
    typed_config:
      "@type": type.googleapis.com/envoy.extensions.filters.http.lua.v3.LuaPerRoute
      default_source_code:
        inline_string: |
          function envoy_on_request(request_handle)
            -- Add a custom header to every request
            request_handle:headers():add("x-request-id-forwarded", 
              request_handle:headers():get("x-request-id") or "none")

            -- Log the request path
            request_handle:logInfo("Request path: " .. 
              request_handle:headers():get(":path"))
          end

          function envoy_on_response(response_handle)
            -- Remove a sensitive response header
            response_handle:headers():remove("server")

            -- Add a custom response header
            response_handle:headers():add("x-powered-by", "envoy")
          end
```

## Lua API

**Headers API** (`request_handle:headers()` / `response_handle:headers()`):
- `:get(name)` — get header value (nil if absent)
- `:add(name, value)` — add a header
- `:replace(name, value)` — replace a header
- `:remove(name)` — remove a header

**Body API** (`request_handle:body()` / `response_handle:body()`):
- `:getBytes(start, length)` — get raw bytes from the body buffer

**Logging** (`request_handle:logTrace/Debug/Info/Warn/Error(msg)`):
- Logs to Envoy's standard output with the appropriate log level

**Responding** (`request_handle:respond(headers, body)`):
- Short-circuits the filter chain and returns a synthetic response

## Example: Path Normalization

```lua
function envoy_on_request(request_handle)
  local path = request_handle:headers():get(":path")
  -- Strip trailing slash
  if path ~= "/" and path:sub(-1) == "/" then
    request_handle:headers():replace(":path", path:sub(1, -2))
  end
end
```

## Limitations

- No access to the Envoy cluster API (cannot make upstream HTTP calls from Lua)
- Scripts must be non-blocking
- Limited to the Lua standard library (no external modules)
- For async HTTP calls to external services, use the ext_authz filter or ext_proc instead
