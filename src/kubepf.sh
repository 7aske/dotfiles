#!/usr/bin/env bash

context="$(kubectl config get-contexts --output name | fzf)"

[ -z "$context" ] && exit 1

namespace="$(kubectl --context $context get namespaces --output name | cut -d/ -f2 | fzf)"

[ -z "$namespace" ] && exit 1

pod="$(kubectl --context $context --namespace $namespace get pods --output name | cut -d/ -f2 | fzf)"

port="$(kubectl get pod -n $namespace $pod --output json | jq ".spec.containers.[].ports.[].containerPort" | xargs -I% echo "%:%" | fzf --print-query)"

[ -z "$port" ] && exit 1

kubectl --context $context --namespace $namespace port-forward pods/$pod "$port"
