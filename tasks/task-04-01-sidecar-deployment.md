# Task 04-01 — Sidecar Deployment in Kubernetes

> **Story:** [Envoy as Sidecar](../stories/story-04-01-envoy-as-sidecar.md)  
> **Effort:** ~45 minutes  
> **Prerequisites:** `kubectl` with a running cluster (local `kind`, `minikube`, or AKS)

---

## Objective

Deploy Envoy as a sidecar alongside a simple Python backend in Kubernetes. Access the backend exclusively through the Envoy proxy and verify metrics collection.

---

## Step 1: Create the Backend Application

```yaml
# backend-deployment.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: envoy-sidecar-config
data:
  envoy.yaml: |
    static_resources:
      listeners:
        - name: listener_0
          address:
            socket_address:
              address: 0.0.0.0
              port_value: 8000   # External port (proxy)
          filter_chains:
            - filters:
                - name: envoy.filters.network.http_connection_manager
                  typed_config:
                    "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
                    stat_prefix: ingress_http
                    route_config:
                      virtual_hosts:
                        - name: local
                          domains: ["*"]
                          routes:
                            - match: { prefix: "/" }
                              route:
                                cluster: local_app
                    http_filters:
                      - name: envoy.filters.http.router
                        typed_config:
                          "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router
      clusters:
        - name: local_app
          type: STATIC
          connect_timeout: 5s
          load_assignment:
            cluster_name: local_app
            endpoints:
              - lb_endpoints:
                  - endpoint:
                      address:
                        socket_address:
                          address: 127.0.0.1   # localhost within the Pod
                          port_value: 8080
    admin:
      address:
        socket_address:
          address: 0.0.0.0
          port_value: 9901
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-with-sidecar
  labels:
    app: app-with-sidecar
spec:
  replicas: 2
  selector:
    matchLabels:
      app: app-with-sidecar
  template:
    metadata:
      labels:
        app: app-with-sidecar
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9901"
        prometheus.io/path: "/stats/prometheus"
    spec:
      volumes:
        - name: envoy-config
          configMap:
            name: envoy-sidecar-config

      containers:
        # Main application
        - name: app
          image: kennethreitz/httpbin
          ports:
            - containerPort: 80
              name: http
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 200m
              memory: 128Mi

        # Envoy sidecar
        - name: envoy
          image: envoyproxy/envoy:v1.29-latest
          args:
            - "-c"
            - "/etc/envoy/envoy.yaml"
            - "--log-level"
            - "info"
          ports:
            - containerPort: 8000
              name: proxy
            - containerPort: 9901
              name: admin
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
---
apiVersion: v1
kind: Service
metadata:
  name: app-with-sidecar
spec:
  selector:
    app: app-with-sidecar
  ports:
    - name: proxy
      port: 8000
      targetPort: 8000
    - name: admin
      port: 9901
      targetPort: 9901
  type: ClusterIP
```

---

## Step 2: Deploy

```bash
kubectl apply -f backend-deployment.yaml

# Wait for pods to be ready
kubectl rollout status deployment/app-with-sidecar

# Verify both containers are running in each pod
kubectl get pods -l app=app-with-sidecar
kubectl describe pod -l app=app-with-sidecar | grep -A 20 "Containers:"
```

---

## Step 3: Test via Envoy Sidecar

```bash
# Port-forward to the proxy port (Envoy, not the app directly)
kubectl port-forward svc/app-with-sidecar 8000:8000 &

# Access backend through Envoy
curl http://localhost:8000/ip
curl http://localhost:8000/get | jq .headers
```

---

## Step 4: Access the Admin API

```bash
# Port-forward to admin
kubectl port-forward svc/app-with-sidecar 9901:9901 &

# Check stats
curl http://localhost:9901/stats/prometheus | grep downstream_rq_total
```

---

## Step 5: Verify Metrics Collection

```bash
# Generate traffic
for i in {1..20}; do curl -s http://localhost:8000/get > /dev/null; done

# Check counters
curl -s http://localhost:9901/stats | grep http.ingress_http.downstream_rq_total
```

---

## Clean Up

```bash
kubectl delete -f backend-deployment.yaml
kill $(lsof -t -i:8000) 2>/dev/null
kill $(lsof -t -i:9901) 2>/dev/null
```

---

## Verification

- [ ] Both containers (`app` and `envoy`) running in each pod
- [ ] Traffic reaches httpbin via Envoy sidecar (port 8000)
- [ ] Admin API accessible at port 9901
- [ ] `downstream_rq_total` increments with each request
