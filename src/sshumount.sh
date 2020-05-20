#!/usr/bin/env bash

prog="$(basename $0)"

usage (){
    echo "usage: $prog <mount>"
    exit 1
}

local_mount="/run/mount/$1"

if [ -e "$local_mount" ]; then
    sudo fusermount -u "$local_mount"
else
    echo "$prog: $local_mount: no such file or directory" && exit 1
fi
