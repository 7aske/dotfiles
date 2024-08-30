#!/usr/bin/env bash

# Script for restarting Discord

while $(killall Discord); do echo killing; done

setsid discord &
