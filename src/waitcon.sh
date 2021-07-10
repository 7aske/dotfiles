#!/usr/bin/env bash

# Program that waits for at least one interface to 
# be connected before exiting
# Optionally first argument can be the name of the interface

while [ -z "$(ip link show $1 | grep 'state UP')" ]; do sleep 0.5; done
