# Access Logging

## Enabling Access Logs

Access logs are configured inside the HTTP Connection Manager.

```yaml
access_log:
  - name: envoy.access_loggers.stdout
    typed_config:
      "@type": type.googleapis.com/envoy.extensions.access_loggers.stream.v3.StdoutAccessLog
      log_format:
        json_format:
          timestamp: "%START_TIME%"
          method: "%REQ(:METHOD)%"
          path: "%REQ(X-ENVOY-ORIGINAL-PATH?:PATH)%"
          protocol: "%PROTOCOL%"
          response_code: "%RESPONSE_CODE%"
          response_flags: "%RESPONSE_FLAGS%"
          duration_ms: "%DURATION%"
          upstream_host: "%UPSTREAM_HOST%"
          upstream_cluster: "%UPSTREAM_CLUSTER%"
          downstream_remote: "%DOWNSTREAM_REMOTE_ADDRESS%"
          user_agent: "%REQ(USER-AGENT)%"
          request_id: "%REQ(X-REQUEST-ID)%"
          bytes_sent: "%BYTES_SENT%"
          bytes_received: "%BYTES_RECEIVED%"
```

## File Access Logger

```yaml
access_log:
  - name: envoy.access_loggers.file
    typed_config:
      "@type": type.googleapis.com/envoy.extensions.access_loggers.file.v3.FileAccessLog
      path: /var/log/envoy/access.log
      log_format:
        text_format_source:
          inline_string: "[%START_TIME%] \"%REQ(:METHOD)% %REQ(X-ENVOY-ORIGINAL-PATH?:PATH)% %PROTOCOL%\" %RESPONSE_CODE% %DURATION%ms %BYTES_SENT%b\n"
```

## Key Command Operators for Access Logs

| Operator | Description |
|---|---|
| `%START_TIME%` | Request start timestamp |
| `%REQ(:METHOD)%` | HTTP method |
| `%REQ(:PATH)%` | Request path |
| `%RESPONSE_CODE%` | HTTP response status code |
| `%RESPONSE_FLAGS%` | Envoy's response disposition flags (e.g., `UH`, `UF`) |
| `%DURATION%` | Total request duration in milliseconds |
| `%BYTES_SENT%` | Response bytes sent to client |
| `%BYTES_RECEIVED%` | Request bytes received from client |
| `%UPSTREAM_HOST%` | IP:port of the selected upstream endpoint |
| `%UPSTREAM_CLUSTER%` | Name of the upstream cluster |
| `%DOWNSTREAM_REMOTE_ADDRESS%` | Client IP and port |

## Conditional Access Logging

Log only requests that resulted in errors to reduce log volume:

```yaml
access_log:
  - name: envoy.access_loggers.stdout
    filter:
      or_filter:
        filters:
          - status_code_filter:
              comparison:
                op: GE
                value:
                  default_value: 500
                  runtime_key: access_log_error_threshold
          - duration_filter:
              comparison:
                op: GE
                value:
                  default_value: 5000   # Log requests taking > 5 seconds
                  runtime_key: access_log_slow_threshold
    typed_config:
      "@type": type.googleapis.com/envoy.extensions.access_loggers.stream.v3.StdoutAccessLog
```
