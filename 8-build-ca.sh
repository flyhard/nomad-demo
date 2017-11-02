#!/usr/bin/env bash

set -x

export VAULT_ADDR=http://127.0.0.1:8200

vault unmount example
vault unmount example_ops

# Create root CA

vault mount -path=example -description="Example Root CA" -max-lease-ttl=87600h pki

sleep 10

vault write example/root/generate/internal \
    common_name="Example Root CA" \
    ttl=87600h \
    key_bits=4096 \
    exclude_cn_from_sans=true

curl -s http://localhost:8200/v1/example/ca/pem | openssl x509 -text

sleep 10

vault mount -path=example_ops -description="Example Ops Test Root CA" -max-lease-ttl=87600h pki

vault write -field csr example_ops/intermediate/generate/internal \
    common_name="Example Ops Test Root CA" \
    ttl=26280h \
    key_bits=4096 \
    exclude_cn_from_sans=true |tee example_ops.csr

sleep 10

vault write -field certificate example/root/sign-intermediate \
    csr=@example_ops.csr \
    common_name="Example Ops Intermediate CA" \
    ttl=8760h | tee example_ops.crt

sleep 10

vault write -format json example_ops/intermediate/set-signed \
    certificate=@example_ops.crt

curl -s http://localhost:8200/v1/example_ops/ca/pem | openssl x509 -text | head -20

vault write example_ops/config/urls \
    issuing_certificates="http://127.0.0.1:8200/v1/example_ops/ca" \
    crl_distribution_points="http://127.0.0.1:8200/v1/example_ops/crl"
