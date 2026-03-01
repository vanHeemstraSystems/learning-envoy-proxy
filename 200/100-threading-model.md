# Threading Model

## Overview

Envoy uses a **single-process, multi-threaded architecture** built on an event loop (libevent). It does not use blocking I/O.

## Thread Types

**Main Thread**
- Bootstraps the process
- Manages xDS (control plane) connections
- Handles admin API requests
- Coordinates configuration updates

**Worker Threads**
- One per CPU core by default (configurable via `--concurrency`)
- Each runs its own event loop
- Handles all I/O for connections assigned to it
- No shared state between workers — each has its own connection table

**File Flush Thread**
- Handles asynchronous flushing of access log buffers

## Why This Matters

Because there is **no shared state** between worker threads, Envoy avoids lock contention and scales linearly with CPU cores. This is why Envoy can handle hundreds of thousands of concurrent connections efficiently.

When a new TCP connection arrives, it is assigned to a worker thread and stays on that thread for its lifetime.

## Configuration

```yaml
# In the bootstrap config
node:
  id: my-envoy
  cluster: my-cluster

# Concurrency is set via CLI flag:
# envoy --concurrency 4 -c envoy.yaml
```

## Implications for Filter Development

Filters run on worker threads. They must be non-blocking. Any blocking operation (e.g., a synchronous HTTP call to an external service) will stall all connections on that worker thread. This is why external authorization uses an async gRPC call, not a synchronous HTTP call.
