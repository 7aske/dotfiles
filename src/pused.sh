#!/usr/bin/env bash

PORT="$1"

exit $(netstat -tln | grep -cE "[\\d.:a-f]*:$PORT")
