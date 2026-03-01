# Task 01-01 — Install Envoy

> **Story:** [What is Envoy?](../stories/story-01-01-what-is-envoy.md)  
> **Effort:** ~15 minutes  
> **Prerequisites:** Docker installed

---

## Objective

Install and run Envoy locally using Docker. Verify the admin API is accessible.

---

## Step 1: Pull the Official Envoy Image

```bash
# Pull the latest stable Envoy image
docker pull envoyproxy/envoy:v1.29-latest

# Verify the image
docker inspect envoyproxy/envoy:v1.29-latest | jq '.[0].Config.Cmd'
```

---

## Step 2: Check the Envoy Version

```bash
docker run --rm envoyproxy/envoy:v1.29-latest envoy --version
```

Expected output:
```
envoy  version: ...
```

---

## Step 3: Run Envoy with the Built-in Demo Config

Envoy ships with a demo configuration at `/etc/envoy/envoy.yaml`:

```bash
docker run -d \
  --name envoy-demo \
  -p 10000:10000 \
  -p 9901:9901 \
  envoyproxy/envoy:v1.29-latest
```

---

## Step 4: Verify the Admin API

```bash
# Check Envoy is ready
curl http://localhost:9901/ready

# View server info
curl http://localhost:9901/server_info | jq .

# View active listeners
curl http://localhost:9901/listeners | jq .

# View clusters
curl http://localhost:9901/clusters
```

---

## Step 5: View Prometheus Metrics

```bash
# Pull a sample of metrics
curl -s http://localhost:9901/stats/prometheus | head -50
```

---

## Step 6: View the Running Configuration

```bash
# Full config dump
curl -s http://localhost:9901/config_dump | jq . | head -100
```

---

## Step 7: Stop and Clean Up

```bash
docker stop envoy-demo
docker rm envoy-demo
```

---

## Verification

You have successfully completed this task when:
- [ ] `curl http://localhost:9901/ready` returns `LIVE`
- [ ] `curl http://localhost:9901/server_info` returns JSON with the Envoy version
- [ ] `curl http://localhost:9901/listeners` shows at least one listener
- [ ] `curl http://localhost:9901/stats/prometheus` returns metrics

---

## Troubleshooting

| Issue | Fix |
|---|---|
| Port 10000 in use | Use `-p 10001:10000` |
| Port 9901 in use | Use `-p 9902:9901` |
| Container exits immediately | Run `docker logs envoy-demo` to see error |

---

*Next: [Task 01-02 — First Proxy](task-01-02-first-proxy.md)*
