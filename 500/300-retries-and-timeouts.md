# Retries and Timeouts

## Timeouts

Timeouts in Envoy are configured at the route level and apply to each individual request.

```yaml
routes:
  - match:
      prefix: "/"
    route:
      cluster: my_service
      timeout: 15s           # Total request timeout (0 = disabled)
      idle_timeout: 300s     # Stream idle timeout (for long-lived gRPC streams)
      retry_policy:
        retry_on: connect-failure,reset,5xx
        num_retries: 3
        per_try_timeout: 5s  # Timeout for each individual attempt
```

**Timeout hierarchy**: `per_try_timeout` × `num_retries` should be less than `timeout` to allow all retries to complete before the overall deadline.

## Retry Policy

**`retry_on`** — comma-separated conditions that trigger a retry:

| Condition | Triggers On |
|---|---|
| `5xx` | Any 5xx HTTP response from upstream |
| `connect-failure` | TCP connection failure to upstream |
| `reset` | Upstream reset (RST) of the TCP stream |
| `retriable-4xx` | Only HTTP 409 (Conflict) by default |
| `retriable-headers` | Upstream returns headers matching a retry header matcher |
| `grpc-cancelled` | gRPC status CANCELLED |
| `grpc-unavailable` | gRPC status UNAVAILABLE |

**`num_retries`** — maximum number of retry attempts (not including the original).

**`per_try_timeout`** — timeout for each attempt. If not set, the route's overall `timeout` applies.

## Retry Budget

To prevent retry storms (all Envoy instances retrying simultaneously and overwhelming an already-failing upstream), use a **retry budget** that caps the total number of active retries relative to active requests:

```yaml
retry_policy:
  retry_on: 5xx
  retry_budget:
    budget_percent:
      value: 20.0   # Allow at most 20% of active requests to be retries
    min_retry_concurrency: 3
```

## Hedged Requests

For latency-sensitive scenarios, Envoy can send a second "hedge" request to a different upstream endpoint after a delay if the first hasn't responded:

```yaml
hedge_policy:
  hedge_on_per_try_timeout: true   # Send hedge when per_try_timeout fires
```

The first response received is used and the other is cancelled.
