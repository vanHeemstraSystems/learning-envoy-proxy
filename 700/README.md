# 700 - Security

Envoy handles all aspects of transport and application-layer security — TLS termination, mutual TLS for service-to-service authentication, JWT validation, RBAC authorization, and external authorization delegation.

## Contents

| File | Description |
|---|---|
| [100-tls-termination.md](100-tls-termination.md) | HTTPS termination configuration |
| [200-mtls-mutual-tls.md](200-mtls-mutual-tls.md) | Service-to-service mutual TLS |
| [300-jwt-authentication.md](300-jwt-authentication.md) | JWT validation with the jwt_authn filter |
| [400-rbac-authorization.md](400-rbac-authorization.md) | Role-Based Access Control filter |
| [500-external-authorization.md](500-external-authorization.md) | Delegating auth to OPA or custom service |
