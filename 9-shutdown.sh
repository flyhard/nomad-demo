#!/usr/bin/env bash

nomad stop fabio
nomad stop hashiui

nomad node-drain -enable -self

sleep 5

killall nomad
killall vault
killall consul