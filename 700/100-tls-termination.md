# TLS Termination

## What Is TLS Termination?

TLS termination means Envoy decrypts incoming HTTPS connections, processes the HTTP request in plaintext, and optionally re-encrypts when forwarding to the upstream. The application service does not need to handle TLS at all.

## Basic HTTPS Listener

```yaml
listeners:
  - name: https_listener
    address:
      socket_address:
        address: 0.0.0.0
        port_value: 443
    listener_filters:
      - name: envoy.filters.listener.tls_inspector
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.listener.tls_inspector.v3.TlsInspector
    filter_chains:
      - transport_socket:
          name: envoy.transport_sockets.tls
          typed_config:
            "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.DownstreamTlsContext
            common_tls_context:
              tls_certificates:
                - certificate_chain:
                    filename: /etc/certs/server.crt
                  private_key:
                    filename: /etc/certs/server.key
              alpn_protocols: ["h2", "http/1.1"]
        filters:
          - name: envoy.filters.network.http_connection_manager
            typed_config:
              # ... HCM config
```

## HTTP → HTTPS Redirect

Create a plain HTTP listener on port 80 that redirects all traffic to HTTPS:

```yaml
listeners:
  - name: http_redirect
    address:
      socket_address:
        address: 0.0.0.0
        port_value: 80
    filter_chains:
      - filters:
          - name: envoy.filters.network.http_connection_manager
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
              stat_prefix: http_redirect
              route_config:
                virtual_hosts:
                  - name: redirect
                    domains: ["*"]
                    routes:
                      - match:
                          prefix: "/"
                        redirect:
                          https_redirect: true
                          port_redirect: 443
              http_filters:
                - name: envoy.filters.http.router
                  typed_config:
                    "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router
```

## TLS Version and Cipher Configuration

```yaml
common_tls_context:
  tls_params:
    tls_minimum_protocol_version: TLSv1_2
    tls_maximum_protocol_version: TLSv1_3
    cipher_suites:
      - TLS_AES_128_GCM_SHA256
      - TLS_AES_256_GCM_SHA384
      - ECDHE-RSA-AES128-GCM-SHA256
```

## OCSP Stapling

For improved TLS performance (avoids client OCSP lookups):

```yaml
tls_certificates:
  - certificate_chain:
      filename: /etc/certs/server.crt
    private_key:
      filename: /etc/certs/server.key
    ocsp_staple:
      filename: /etc/certs/server.ocsp
```
