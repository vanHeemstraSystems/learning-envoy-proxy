# RBAC Authorization

## Overview

The **RBAC HTTP filter** (`envoy.filters.http.rbac`) enforces Role-Based Access Control policies on HTTP requests. It evaluates each request against a set of policies and either allows or denies it based on matches against principals (identities) and permissions (actions).

## RBAC Modes

**ALLOW mode** (whitelist) — only explicitly allowed requests pass through. Everything else is denied with a `403`.

**DENY mode** (blacklist) — explicitly denied requests are blocked. Everything else passes. Use this to block specific patterns without defining exhaustive allow rules.

## Configuration Structure

```yaml
- name: envoy.filters.http.rbac
  typed_config:
    "@type": type.googleapis.com/envoy.extensions.filters.http.rbac.v3.RBAC
    rules:
      action: ALLOW            # ALLOW or DENY
      policies:
        read_only_api:
          permissions:
            - and_rules:
                rules:
                  - header:
                      name: ":method"
                      exact_match: "GET"
                  - url_path:
                      path:
                        prefix: "/api/"
          principals:
            - any: true        # Any authenticated principal

        admin_write:
          permissions:
            - any: true        # All methods and paths
          principals:
            - metadata:
                filter: envoy.filters.http.jwt_authn
                path:
                  - key: jwt_payload
                  - key: role
                value:
                  string_match:
                    exact: "admin"
```

## Permission Matchers

| Matcher | Description |
|---|---|
| `header` | Match on HTTP header name/value |
| `url_path` | Match on request path |
| `destination_port` | Match on destination port |
| `source_ip` | Match on source IP CIDR |
| `any` | Match everything |
| `and_rules` / `or_rules` | Combine matchers with AND/OR logic |
| `not_rule` | Negate a matcher |

## Principal Matchers

| Matcher | Description |
|---|---|
| `any` | Any principal (authenticated or not) |
| `source_ip` | Source IP CIDR range |
| `header` | Request header (e.g., `x-user-id`) |
| `metadata` | Filter metadata (e.g., JWT claims from jwt_authn) |
| `authenticated.principal_name` | mTLS certificate SAN |

## Shadow Mode (Dry Run)

Test RBAC policies without enforcing them by using `shadow_rules_stat_prefix`. Envoy evaluates the shadow rules and records metrics (allow/deny counts) but does not actually block requests.

```yaml
rules:
  action: ALLOW
  policies: { ... }
shadow_rules:
  action: ALLOW
  policies: { ... new stricter policy ... }
shadow_rules_stat_prefix: "shadow_rbac_"
```
