#!/usr/bin/env bash

context="$(kubectl config current-context)"

function exit_if_empty() {
    [ -z "$1" ] && echo "Must select a $2" && exit 1
}

function get_port() {
    random_port="$(shuf -i 10000-65535 -n 1)"

    while nc -z localhost $random_port; do
        random_port="$(shuf -i 10000-65535 -n 1)"
    done

    echo $random_port
}

while getopts "c:n:p:d:" opt; do
    case $opt in
        c) context="$OPTARG";;
        n) namespace="$OPTARG";;
        d) deployment="$OPTARG";;
        p) port="$OPTARG";;
    esac
done

if [ -z "$context" ]; then
    context="$(kubectl config get-contexts --output name | fzf)"
fi

exit_if_empty "$context" "context"

if [ -z "$namespace" ]; then
    namespace="$(kubectl --context $context get namespaces --output name | cut -d/ -f2 | fzf)"
fi

exit_if_empty "$namespace" "namespace"

if [ -z "$deployment" ]; then
    deployment="$(kubectl --context $context -n $namespace get deployments --output name | cut -d/ -f2 | fzf)"
fi

exit_if_empty "$deployment" "deployment"

if [ -z "$port" ]; then
    port="$(kubectl --context $context get -n $namespace deployment/$deployment -o json | jq ".spec.template.spec.containers.[].ports.[].containerPort" | fzf --print-query | tr -d '\n"')"
fi

exit_if_empty "$port" "port"

local_port="$(get_port)"

trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT
kubectl --context $context -n $namespace port-forward deployments/$deployment "$local_port:$port" &

echo "Port forwarding $deployment:$port to localhost:$local_port"

while true; do
    read -p "(q)uit,(o)pen browser: " answ
    case $answ in
        [Qq]* ) exit 0 ;;
        [Oo]* ) xdg-open "http://localhost:$local_port";;
    esac
done
