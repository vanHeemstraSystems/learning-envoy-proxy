# Task 02-02 — xDS Server in Python

> **Story:** [xDS Dynamic Configuration API](../stories/story-02-02-xds-api.md)  
> **Effort:** ~60 minutes  
> **Prerequisites:** Python 3.11+, `pip`

---

## Objective

Build a minimal gRPC xDS server in Python that serves Cluster and Listener resources to Envoy dynamically. Modify the configuration at runtime and observe Envoy updating without a restart.

---

## Step 1: Install Dependencies

```bash
pip install grpcio grpcio-tools envoy-data-plane-api
# Or:
pip install grpcio aiohttp
pip install git+https://github.com/envoyproxy/python-control-plane
```

Since a full Python xDS library is complex, we use **go-control-plane** via Docker for the actual server and focus on a Python **REST-to-xDS bridge** pattern:

---

## Step 2: Project Structure

```
xds-server/
├── docker-compose.yml
├── control-plane/
│   ├── Dockerfile
│   └── main.go
├── envoy/
│   └── bootstrap.yaml
└── backend/
    └── Dockerfile
```

---

## Step 3: Simple go-control-plane Server

Create `control-plane/main.go`:

```go
package main

import (
    "context"
    "fmt"
    "log"
    "net"
    "time"

    core "github.com/envoyproxy/go-control-plane/envoy/config/core/v3"
    endpoint "github.com/envoyproxy/go-control-plane/envoy/config/endpoint/v3"
    cluster "github.com/envoyproxy/go-control-plane/envoy/config/cluster/v3"
    listener "github.com/envoyproxy/go-control-plane/envoy/config/listener/v3"
    route "github.com/envoyproxy/go-control-plane/envoy/config/route/v3"
    hcm "github.com/envoyproxy/go-control-plane/envoy/extensions/filters/network/http_connection_manager/v3"
    router "github.com/envoyproxy/go-control-plane/envoy/extensions/filters/http/router/v3"
    "github.com/envoyproxy/go-control-plane/pkg/cache/v3"
    "github.com/envoyproxy/go-control-plane/pkg/resource/v3"
    "github.com/envoyproxy/go-control-plane/pkg/server/v3"
    clusterservice "github.com/envoyproxy/go-control-plane/envoy/service/cluster/v3"
    discoverygrpc "github.com/envoyproxy/go-control-plane/envoy/service/discovery/v3"
    endpointservice "github.com/envoyproxy/go-control-plane/envoy/service/endpoint/v3"
    listenerservice "github.com/envoyproxy/go-control-plane/envoy/service/listener/v3"
    routeservice "github.com/envoyproxy/go-control-plane/envoy/service/route/v3"
    "github.com/golang/protobuf/ptypes/wrappers"
    "google.golang.org/grpc"
    "google.golang.org/protobuf/types/known/anypb"
    "google.golang.org/protobuf/types/known/durationpb"
)

const (
    nodeID = "envoy-learning"
)

func makeCluster(name, address string, port uint32) *cluster.Cluster {
    return &cluster.Cluster{
        Name:                 name,
        ConnectTimeout:       durationpb.New(5 * time.Second),
        ClusterDiscoveryType: &cluster.Cluster_Type{Type: cluster.Cluster_STATIC},
        LbPolicy:             cluster.Cluster_ROUND_ROBIN,
        LoadAssignment: &endpoint.ClusterLoadAssignment{
            ClusterName: name,
            Endpoints: []*endpoint.LocalityLbEndpoints{{
                LbEndpoints: []*endpoint.LbEndpoint{{
                    HostIdentifier: &endpoint.LbEndpoint_Endpoint{
                        Endpoint: &endpoint.Endpoint{
                            Address: &core.Address{
                                Address: &core.Address_SocketAddress{
                                    SocketAddress: &core.SocketAddress{
                                        Protocol: core.SocketAddress_TCP,
                                        Address:  address,
                                        PortSpecifier: &core.SocketAddress_PortValue{
                                            PortValue: port,
                                        },
                                    },
                                },
                            },
                        },
                    },
                }},
            }},
        },
    }
}

func makeListener(clusterName string) *listener.Listener {
    routerConfig, _ := anypb.New(&router.Router{})
    manager, _ := anypb.New(&hcm.HttpConnectionManager{
        StatPrefix: "ingress_http",
        RouteSpecifier: &hcm.HttpConnectionManager_RouteConfig{
            RouteConfig: &route.RouteConfiguration{
                Name: "local_route",
                VirtualHosts: []*route.VirtualHost{{
                    Name:    "local_service",
                    Domains: []string{"*"},
                    Routes: []*route.Route{{
                        Match: &route.RouteMatch{
                            PathSpecifier: &route.RouteMatch_Prefix{Prefix: "/"},
                        },
                        Action: &route.Route_Route{
                            Route: &route.RouteAction{
                                ClusterSpecifier: &route.RouteAction_Cluster{
                                    Cluster: clusterName,
                                },
                            },
                        },
                    }},
                }},
            },
        },
        HttpFilters: []*hcm.HttpFilter{{
            Name: "envoy.filters.http.router",
            ConfigType: &hcm.HttpFilter_TypedConfig{
                TypedConfig: routerConfig,
            },
        }},
    })
    return &listener.Listener{
        Name: "listener_0",
        Address: &core.Address{
            Address: &core.Address_SocketAddress{
                SocketAddress: &core.SocketAddress{
                    Protocol: core.SocketAddress_TCP,
                    Address:  "0.0.0.0",
                    PortSpecifier: &core.SocketAddress_PortValue{PortValue: 10000},
                },
            },
        },
        FilterChains: []*listener.FilterChain{{
            Filters: []*listener.Filter{{
                Name: "envoy.filters.network.http_connection_manager",
                ConfigType: &listener.Filter_TypedConfig{TypedConfig: manager},
            }},
        }},
    }
}

func main() {
    snapshotCache := cache.NewSnapshotCache(false, cache.IDHash{}, nil)

    snap, _ := cache.NewSnapshot("1",
        map[resource.Type][]types.Resource{
            resource.ClusterType:  {makeCluster("backend", "host.docker.internal", 8080)},
            resource.ListenerType: {makeListener("backend")},
        },
    )
    snapshotCache.SetSnapshot(context.Background(), nodeID, snap)

    srv := server.NewServer(context.Background(), snapshotCache, nil)
    grpcServer := grpc.NewServer()

    discoverygrpc.RegisterAggregatedDiscoveryServiceServer(grpcServer, srv)
    clusterservice.RegisterClusterDiscoveryServiceServer(grpcServer, srv)
    listenerservice.RegisterListenerDiscoveryServiceServer(grpcServer, srv)
    routeservice.RegisterRouteDiscoveryServiceServer(grpcServer, srv)
    endpointservice.RegisterEndpointDiscoveryServiceServer(grpcServer, srv)

    lis, _ := net.Listen("tcp", ":18000")
    log.Println("xDS server listening on :18000")
    log.Fatal(grpcServer.Serve(lis))
}
```

---

## Step 4: Envoy Bootstrap for xDS

Create `envoy/bootstrap.yaml`:

```yaml
node:
  id: envoy-learning
  cluster: learning-cluster

dynamic_resources:
  ads_config:
    api_type: GRPC
    transport_api_version: V3
    grpc_services:
      - envoy_grpc:
          cluster_name: xds_cluster
  cds_config:
    resource_api_version: V3
    ads: {}
  lds_config:
    resource_api_version: V3
    ads: {}

static_resources:
  clusters:
    - name: xds_cluster
      connect_timeout: 5s
      type: STATIC
      http2_protocol_options: {}
      load_assignment:
        cluster_name: xds_cluster
        endpoints:
          - lb_endpoints:
              - endpoint:
                  address:
                    socket_address:
                      address: control-plane
                      port_value: 18000

admin:
  address:
    socket_address:
      address: 0.0.0.0
      port_value: 9901
```

---

## Step 5: Docker Compose

```yaml
# docker-compose.yml
version: "3.8"
services:
  control-plane:
    build: ./control-plane
    ports:
      - "18000:18000"

  envoy:
    image: envoyproxy/envoy:v1.29-latest
    volumes:
      - ./envoy/bootstrap.yaml:/etc/envoy/envoy.yaml
    ports:
      - "10000:10000"
      - "9901:9901"
    depends_on:
      - control-plane

  backend:
    image: kennethreitz/httpbin
    ports:
      - "8080:80"
```

---

## Step 6: Run and Test

```bash
docker compose up -d

# Wait for Envoy to connect and pull config
sleep 5

# Test proxy
curl http://localhost:10000/ip

# Watch Envoy logs for xDS messages
docker compose logs envoy -f
```

---

## Step 7: Dynamic Update (Modify the Cluster)

Modify `main.go` to change the backend port or add a second cluster, rebuild, and observe Envoy updating without restart.

---

## Verification

- [ ] Envoy starts with dynamic config from xDS server
- [ ] Traffic is proxied via the dynamically configured listener and cluster
- [ ] Envoy logs show `lds: add/update listener 'listener_0'` and `cds: add/update cluster 'backend'`
- [ ] Admin config_dump shows dynamic listeners and clusters (not static)
