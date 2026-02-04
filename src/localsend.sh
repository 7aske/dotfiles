#!/usr/bin/env sh

LOCALSEND_FILE="/tmp/localsend"

/opt/localsend/localsend >"$LOCALSEND_FILE" 2>&1
