#!/usr/bin/env bash

[ -z "$1" ] && exit 1

trap 'exit 130' SIGINT

while $(killall $1); do echo "killing $1"; sleep 0.5; done
