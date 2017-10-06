#!/usr/bin/env bash

echo Cleaning up leftovers

killall nomad
killall fabio
killall hashi-ui
killall vault
killall consul

echo
echo Starting consul in the background

consul agent -dev -log-level=info | tee consul.log
