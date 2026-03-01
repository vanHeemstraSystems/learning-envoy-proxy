# External Processing (ext_proc)

## What Is ext_proc?

The **ext_proc filter** (`envoy.filters.http.ext_proc`) sends HTTP request and response data to an external gRPC service for processing. Unlike ext_authz (which only makes allow/deny decisions), ext_proc allows the external service to **modify** headers and body content.

## Use Cases

- Request/response body transformation (e.g., format conversion, PII redaction)
- Header enrichment from an external data source
- Complex content inspection (DLP, antivirus scanning)
- AI/ML inference on request content before routing

## How It Works

For each HTTP request (and optionally response), Envoy streams message chunks to the ext_proc gRPC server:

1. Request headers → gRPC server responds: continue, modify headers, or reject
2. Request body chunks (if configured) → server can modify body
3. Response headers → server can modify or add headers
4. Response body chunks → server can modify body

The external service runs a gRPC streaming server implementing the `ExternalProcessor` service.

## Configuration

```yaml
- name: envoy.filters.http.ext_proc
  typed_config:
    "@type": type.googleapis.com/envoy.extensions.filters.http.ext_proc.v3.ExternalProcessor
    grpc_service:
      envoy_grpc:
        cluster_name: ext_proc_cluster
      timeout: 5s
    failure_mode_allow: false   # Reject request if ext_proc service is unavailable
    processing_mode:
      request_header_mode: SEND     # Always send request headers
      response_header_mode: SEND    # Always send response headers
      request_body_mode: NONE       # Don't send request body (performance)
      response_body_mode: NONE      # Don't send response body
    message_timeout: 2s             # Timeout for each individual message exchange
    max_message_timeout: 10s        # Maximum allowed by the server to request a longer timeout
```

## ext_proc vs ext_authz

| Capability | ext_authz | ext_proc |
|---|---|---|
| Allow/Deny | Yes | Yes |
| Modify request headers | Limited (via response headers) | Yes |
| Modify response headers | No | Yes |
| Modify request body | No | Yes |
| Modify response body | No | Yes |
| Bidirectional streaming | No | Yes |

Use ext_authz for pure authorization decisions. Use ext_proc when you need to transform content.
