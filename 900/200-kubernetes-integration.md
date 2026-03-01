# Kubernetes Integration

## Envoy as an Ingress Controller

Several Kubernetes ingress controllers use Envoy as the underlying proxy:

**Contour** — CNCF project that translates Kubernetes `Ingress` and `HTTPProxy` (its CRD) resources to Envoy xDS configuration via the internal Contour control plane.

```bash
# Install Contour
kubectl apply -f https://projectcontour.io/quickstart/contour.yaml
```

**Ambassador (Emissary-Ingress)** — Uses Envoy and exposes configuration via `Mapping` CRDs.

## Envoy as a Sidecar

Istio auto-injects Envoy sidecars into pods in labeled namespaces:

```bash
# Enable auto-injection for a namespace
kubectl label namespace my-app istio-injection=enabled
```

When Istio is installed via the AKS add-on:
```bash
kubectl label namespace my-app istio.io/rev=asm-1-19
```

## Envoy Admin in Kubernetes

Access the admin API of a running sidecar:

```bash
# Port-forward the admin port
kubectl port-forward pod/my-pod 15000:15000

# Then in another terminal
curl http://localhost:15000/config_dump | jq .
curl http://localhost:15000/stats | grep circuit
```

## ConfigMap-Based Static Configuration

For manually managed (non-Istio) Envoy deployments, store config in a ConfigMap:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: envoy-config
data:
  envoy.yaml: |
    static_resources:
      # ... full envoy.yaml content
```

Mount it in the pod:
```yaml
volumes:
  - name: envoy-config
    configMap:
      name: envoy-config
containers:
  - name: envoy
    volumeMounts:
      - name: envoy-config
        mountPath: /etc/envoy
```

**Important**: ConfigMap updates do not automatically reload Envoy. You must restart the pod or use a sidecar watcher that sends a SIGHUP. For production, use xDS-based configuration (Istio/Contour).

## Kubernetes Service Discovery

For STRICT_DNS clusters, use the Kubernetes DNS service name:

```yaml
clusters:
  - name: my_service
    type: STRICT_DNS
    load_assignment:
      cluster_name: my_service
      endpoints:
        - lb_endpoints:
            - endpoint:
                address:
                  socket_address:
                    address: my-service.my-namespace.svc.cluster.local
                    port_value: 8080
```

For EDS-based discovery (with a control plane), endpoints are pushed dynamically — Envoy does not need to resolve DNS for each pod.
