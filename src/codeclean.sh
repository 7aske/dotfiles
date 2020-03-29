#!/usr/bin/env sh

[ -z "$CODE" ] && echo "'CODE' not set" && exit 0

find "$CODE" -type d \( -name out -or -name target -or -name cmake-build-release -or -name cmake-build-debug -or -name dist -or -name node_modules -or -name build -or -name __pycache__ -or -name venv \) -exec rm -rf {} \;


