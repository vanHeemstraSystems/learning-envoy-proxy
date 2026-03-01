#!/usr/bin/env bash
# generate-certs.sh — Generate self-signed CA, server, and client certificates for mTLS lab
set -euo pipefail

echo "==> Generating CA key and certificate..."
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -sha256 -days 365 -out ca.crt \
  -subj "/CN=Test CA/O=Atlas IDP Learning/C=NL"

echo "==> Generating server key and certificate..."
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr \
  -subj "/CN=my-service/O=Atlas IDP/C=NL"
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key \
  -CAcreateserial -out server.crt -days 365 -sha256

echo "==> Generating client key and certificate..."
openssl genrsa -out client.key 2048
openssl req -new -key client.key -out client.csr \
  -subj "/CN=my-client/O=Atlas IDP/C=NL"
openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key \
  -CAcreateserial -out client.crt -days 365 -sha256

echo "==> Cleaning up CSR files..."
rm -f server.csr client.csr

echo "==> Done. Generated files:"
ls -la *.crt *.key
