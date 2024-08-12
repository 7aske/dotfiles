#!/usr/bin/env bash

kubectl get --raw /metrics | prom2json | jq '
  .[] | select(.name=="apiserver_requested_deprecated_apis").metrics[].labels
'
