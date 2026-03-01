# Story 04-01 — Envoy as a Sidecar Container

> **Flow:** [Kubernetes](../flows/flow-04-kubernetes.md)  
> **Effort:** ~45 minutes  
> **Task:** [Task 04-01 — Sidecar Deployment](../tasks/task-04-01-sidecar-deployment.md)

---

## The Sidecar Pattern

In Kubernetes, a **sidecar** is an additional container running in the same Pod as the main application container. Sidecars share the Pod's network namespace, meaning they share `localhost` and port space.

This enables Envoy to transparently intercept all network traffic to/from the application — the application doesn't know Envoy exists.

```
┌────────────────────── Pod ──────────────────────┐
│                                                  │
│  ┌─────────────────┐    ┌─────────────────────┐ │
│  │   Application   │    │   Envoy Sidecar     │ │
│  │   :8080         │    │   :15001 (outbound) │ │
│  │                 │    │   :15006 (inbound)  │ │
│  │                 │    │   :9901  (admin)    │ │
│  └─────────────────┘    └─────────────────────┘ │
│                                                  │
│  Shared network namespace (localhost)            │
└──────────────────────────────────────────────────┘
```

---

## Traffic Interception via iptables

Service meshes (like Istio) use an **init container** to set up iptables rules that redirect all traffic through Envoy before the main containers start.

```bash
# iptables rules (simplified) — set up by istio-init
# Redirect all outbound traffic to Envoy's outbound port
iptables -t nat -A OUTPUT -p tcp -j REDIRECT --to-port 15001

# Redirect all inbound traffic to Envoy's inbound port
iptables -t nat -A PREROUTING -p tcp -j REDIRECT --to-port 15006

# Exclude Envoy itself from redirection (avoid loops)
iptables -t nat -A OUTPUT -p tcp -m owner --uid-owner 1337 -j RETURN
```

---

## Manual Sidecar Deployment

Without a service mesh, you can manually deploy Envoy as a sidecar:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      volumes:
        - name: envoy-config
          configMap:
            name: envoy-sidecar-config

      containers:
        # Main application
        - name: app
          image: my-app:latest
          ports:
            - containerPort: 8080

        # Envoy sidecar
        - name: envoy
          image: envoyproxy/envoy:v1.29-latest
          ports:
            - containerPort: 10000   # Proxy port (exposed externally)
            - containerPort: 9901    # Admin port (internal only)
          volumeMounts:
            - name: envoy-config
              mountPath: /etc/envoy
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 500m
              memory: 256Mi
          readinessProbe:
            httpGet:
              path: /ready
              port: 9901
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /ready
              port: 9901
            initialDelaySeconds: 15
            periodSeconds: 20
```

---

## Sidecar vs. Service Mesh

| Approach | Complexity | Automatic | Recommended For |
|---|---|---|---|
| **Manual sidecar** | Low | No | Specific services needing proxy features |
| **Istio (auto-inject)** | High | Yes (per-namespace) | Full mesh, mTLS everywhere |
| **Envoy Gateway** | Medium | Yes (per-Gateway) | North-south ingress |

---

## Summary

The sidecar pattern is the foundation of service mesh architectures. Envoy running as a sidecar provides transparent observability, security, and traffic management without application changes. For Atlas IDP, understand this pattern even if you start with Envoy Gateway — mesh adoption is a natural next step.

---

## Knowledge Check

1. What does "shared network namespace" mean for sidecar containers?
2. How do iptables rules enable transparent traffic interception?
3. What is the purpose of the Envoy readiness probe at `/ready`?
4. When would you choose manual sidecar over Istio auto-injection?
