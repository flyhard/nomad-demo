#!/usr/bin/env bash

echo
echo Starting consul in the background

consul agent -dev -log-level=info | tee consul.log
