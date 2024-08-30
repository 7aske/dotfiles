#!/usr/bin/env bash

prog="$(basename $0)"

usage (){
    echo "usage: $prog <mount>"
    echo "usage: $prog <host> <mount>"
    exit 1
}

[ $# -gt 2 ] && usage


case $# in
    1) 
        mount_point="$1" 
        ;;
    2) 
        host="$(echo "$1" | cut -d '@' -f2)"
        mount_point="$host-$2" 
        ;;
esac

local_mount="/run/mount/$mount_point"

if [ -e "$local_mount" ]; then
    sudo fusermount -u "$local_mount"
    [ -L "$HOME/$mount_point" ] && rm "$HOME/$mount_point"
else
    echo "$prog: $local_mount: no such file or directory" && exit 1
fi
