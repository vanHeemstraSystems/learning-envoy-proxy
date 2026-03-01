# Flow 05 — Advanced Envoy Patterns

## Goal

Implement production-grade security and extensibility patterns: TLS termination, JWT-based authentication with RBAC, and custom logic via WebAssembly (WASM) filters.

## Why This Matters

Security is non-negotiable in the Atlas IDP platform. Envoy's built-in JWT/RBAC filters and WASM extensibility allow you to enforce authentication and authorization at the proxy layer — before traffic reaches your services — without modifying application code.

## Stories in This Flow

| # | Story | Effort |
|---|---|---|
| 05-01 | [TLS Termination & mTLS](../stories/story-05-01-tls-termination.md) | 45 min |
| 05-02 | [JWT Authentication & RBAC](../stories/story-05-02-jwt-rbac.md) | 60 min |
| 05-03 | [WASM Filters for Custom Logic](../stories/story-05-03-wasm-filters.md) | 60 min |

## Tasks in This Flow

| # | Task | Effort |
|---|---|---|
| 05-01 | [JWT Filter](../tasks/task-05-01-jwt-filter.md) | 45 min |

## Learning Outcomes

By the end of this flow you will be able to:

- Configure Envoy to terminate TLS using certificates from Azure Key Vault / cert-manager
- Implement mutual TLS (mTLS) between Envoy sidecars using SDS (Secret Discovery Service)
- Configure the `jwt_authn` HTTP filter to validate JWTs from Azure AD (Entra ID)
- Implement `rbac` policies to authorize requests based on JWT claims
- Compile a Rust or AssemblyScript WASM filter and load it into Envoy
- Explain the WASM ABI and the Proxy-Wasm specification

## Estimated Total Time

~4 hours (reading + hands-on)

---

*Previous: [Flow 04 — Kubernetes](flow-04-kubernetes.md)*  
*Back to: [README](../README.md)*
