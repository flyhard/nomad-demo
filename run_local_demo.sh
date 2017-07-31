#!/usr/bin/env bash
set -x

cd $(dirname $0)
consul agent -dev > consul.log &

nomad agent -dev > nomad.log &

sleep 5

nomad run hashi-ui.nomad

read -p "Press any key to continue" -n1 -s
echo
nomad status hashi-ui
echo
echo

id=$(curl -sS localhost:4646/v1/job/hashi-ui/allocations | jq ".[].ID"| tr -d '"')
port=$(curl -sS localhost:4646/v1/allocation/${id} | jq '.Resources.Networks[].DynamicPorts[]|select(.Label=="UI")|.Value')

echo
echo ID=$id
echo
echo Go to: http://localhost:${port}/
echo
read -p "Press any key to continue" -n1 -s
echo

less tomcat.nomad

nomad run tomcat.nomad

tomcatId=$(curl -sS localhost:4646/v1/job/tomcat/allocations | jq ".[].ID"| tr -d '"')
for i in $tomcatId ; do
    nomad alloc-status ${i}|less
done

read -p "Press any key to END the demo" -n1 -s
echo

kill %2 %1

wait

echo Done