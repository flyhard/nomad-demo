#!/usr/bin/env bash

. ./99-env.sh

echo
echo Starting Vault in the background

vault server -dev -log-level=debug 2>&1 |tee vault.log &

vault audit-enable file file_path=$PWD/audit.log

echo
echo Writing Secret into Vault:

vault write secret/hello value=world

echo
echo Creating policy to allow access to our secret:

vault policy-write secret secret.policy

wait

