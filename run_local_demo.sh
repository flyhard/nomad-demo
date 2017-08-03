#!/usr/bin/env bash
#set -x

cd $(dirname $0)

echo \nStarting consul in the background\n
consul agent -dev > consul.log &

echo \nStarting Vault in the background\n
vault server -dev -log-level=debug 2>&1 > vault.log &
export VAULT_ADDR=http://127.0.0.1:8200

vault audit-enable file file_path=$PWD/audit.log

echo \nWriting Secret into Vault:
vault write secret/hello value=world

echo \nCreating policy to allow access to our secret:
vault policy-write secret secret.policy

echo \nCreating a token for Nomad:
token=$(vault token-create -orphan -policy="root" -format json|jq ".auth.client_token"| tr -d '"')

echo \nStarting Nomad in the background
VAULT_TOKEN=$token nomad agent -config nomad.hcl > nomad.log &

sleep 15

echo \nScheduling our UI to start
nomad run hashi-ui.nomad

read -p "Press any key to continue" -n1 -s
echo
nomad status hashi-ui
echo
echo

id=$(curl -sS localhost:4646/v1/job/hashi-ui/allocations | jq ".[].ID"| tr -d '"')
port=$(curl -sS localhost:4646/v1/allocation/${id} | jq '.Resources.Networks[].DynamicPorts[]|select(.Label=="UI")|.Value')
ip=$(curl -sS localhost:4646/v1/allocation/${id} | jq '.Resources.Networks[].IP'| tr -d '"')

echo contents of our secrets file:
nomad fs ${id} ui/local/file.yml

echo
echo ID=$id
echo
echo Go to: http://${ip}:${port}/
echo
read -p "Press any key to continue" -n1 -s
echo

less tomcat.nomad

nomad run tomcat.nomad

tomcatId=$(curl -sS localhost:4646/v1/job/tomcat/allocations | jq ".[].ID"| tr -d '"')
for i in ${tomcatId} ; do
    nomad alloc-status ${i}|less
done

read -p "Press any key to END the demo" -n1 -s
echo

kill %3 %2 %1
rm -rf /tmp/nomad-data
wait

echo Done