#!/usr/bin/env bash


. ./99-env.sh

echo Cleaning up old data
rm -rf /tmp/nomad-data

echo
echo Creating a token for Nomad:
token=$(vault token-create -orphan -policy="root" -format json|jq ".auth.client_token"| tr -d '"')

echo
echo Starting Nomad in the background

VAULT_TOKEN=$token nomad agent -config nomad.hcl |tee nomad.log
