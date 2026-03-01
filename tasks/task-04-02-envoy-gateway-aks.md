# Task 04-02 — Envoy Gateway on AKS

> **Story:** [Envoy Gateway](../stories/story-04-03-envoy-gateway.md)  
> **Effort:** ~60 minutes  
> **Prerequisites:** AKS cluster with `kubectl` and `helm` configured

---

## Objective

Install Envoy Gateway on AKS, expose a sample application via the Kubernetes Gateway API with HTTPRoute, and configure a retry policy using BackendTrafficPolicy.

---

## Step 1: Prerequisites

```bash
# Verify AKS connectivity
kubectl cluster-info
kubectl get nodes

# Install Helm if not present
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Gateway API CRDs (required before Envoy Gateway)
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml
```

---

## Step 2: Install Envoy Gateway

```bash
# Add Envoy Gateway Helm repo
helm install envoy-gateway \
  oci://docker.io/envoyproxy/gateway-helm \
  --version v1.1.0 \
  -n envoy-gateway-system \
  --create-namespace \
  --wait

# Verify installation
kubectl get pods -n envoy-gateway-system
kubectl get crd | grep gateway.envoyproxy.io
```

---

## Step 3: Create GatewayClass

```yaml
# gatewayclass.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: eg
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
```

```bash
kubectl apply -f gatewayclass.yaml
kubectl get gatewayclass eg
# STATUS should be: Accepted
```

---

## Step 4: Deploy Sample Application

```yaml
# sample-app.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: httpbin
  template:
    metadata:
      labels:
        app: httpbin
    spec:
      containers:
        - name: httpbin
          image: kennethreitz/httpbin
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  namespace: default
spec:
  selector:
    app: httpbin
  ports:
    - port: 80
      targetPort: 80
```

```bash
kubectl apply -f sample-app.yaml
kubectl rollout status deployment/httpbin
```

---

## Step 5: Create Gateway and HTTPRoute

```yaml
# gateway.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: atlas-gateway
  namespace: default
spec:
  gatewayClassName: eg
  listeners:
    - name: http
      protocol: HTTP
      port: 80
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: httpbin-route
  namespace: default
spec:
  parentRefs:
    - name: atlas-gateway
  hostnames:
    - "httpbin.atlas.example.com"   # Update to your domain or use external IP
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: httpbin
          port: 80
```

```bash
kubectl apply -f gateway.yaml

# Wait for Gateway to get an external IP (Azure Load Balancer)
kubectl get gateway atlas-gateway -w
# Note the EXTERNAL-IP when it appears

GATEWAY_IP=$(kubectl get gateway atlas-gateway -o jsonpath='{.status.addresses[0].value}')
echo "Gateway IP: $GATEWAY_IP"
```

---

## Step 6: Test the Gateway

```bash
# Test with Host header
curl -H "Host: httpbin.atlas.example.com" http://$GATEWAY_IP/ip
curl -H "Host: httpbin.atlas.example.com" http://$GATEWAY_IP/get

# If you have a real domain, test directly
curl http://httpbin.atlas.example.com/ip
```

---

## Step 7: Add BackendTrafficPolicy (Retries + Timeout)

```yaml
# backend-policy.yaml
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: BackendTrafficPolicy
metadata:
  name: httpbin-retry-policy
  namespace: default
spec:
  targetRef:
    group: gateway.networking.k8s.io
    kind: HTTPRoute
    name: httpbin-route
  retry:
    numRetries: 3
    retryOn:
      - "5xx"
      - "gateway-error"
    perRetryPolicy:
      timeout: 5s
  timeout:
    request: 30s
```

```bash
kubectl apply -f backend-policy.yaml

# Trigger some 500 errors to test retry
for i in {1..5}; do
  curl -s -o /dev/null -w "%{http_code}\n" \
    -H "Host: httpbin.atlas.example.com" \
    http://$GATEWAY_IP/status/500
done
```

---

## Step 8: Inspect the Generated Envoy Config

```bash
# Find the Envoy pod managed by Envoy Gateway
ENVOY_POD=$(kubectl get pod -n envoy-gateway-system \
  -l gateway.envoyproxy.io/owning-gateway-name=atlas-gateway \
  -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || \
  kubectl get pod -n default -l "gateway.networking.k8s.io/gateway-name=atlas-gateway" \
  -o jsonpath='{.items[0].metadata.name}')

# Port-forward to admin API
kubectl port-forward -n envoy-gateway-system $ENVOY_POD 19000:19000 &

# View the generated config
curl -s http://localhost:19000/config_dump | jq '.configs[] | select(.["@type"] | contains("ListenersConfigDump"))'
```

---

## Clean Up

```bash
kubectl delete httproute httpbin-route
kubectl delete gateway atlas-gateway
kubectl delete gatewayclass eg
kubectl delete deployment httpbin
kubectl delete service httpbin
helm uninstall envoy-gateway -n envoy-gateway-system
kubectl delete namespace envoy-gateway-system
```

---

## Verification

- [ ] Envoy Gateway pods running in `envoy-gateway-system` namespace
- [ ] Gateway receives an external IP from Azure Load Balancer
- [ ] `curl -H "Host: ..." http://$GATEWAY_IP/ip` returns a response
- [ ] BackendTrafficPolicy applies retry behavior on 5xx responses
