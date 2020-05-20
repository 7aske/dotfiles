#!/usr/bin/env bash

prog="$(basename $0)"

usage (){
    echo "usage: $prog [user@]<host> <mount>"
    exit 1
}

if [ -z "$1" ] || [ -z "$2" ]; then
    usage 
fi

host="$(echo "$1" | cut -d '@' -f2)"
local_mount="/run/mount/$host-$2"

if [ ! -e "$local_mount" ]; then
    sudo mkdir "$local_mount"
    sudo chown "$USER:plugdev" "$local_mount"
fi

[ ! -L "$HOME/$(basename "$local_mount")" ] && ln -sf "$local_mount" "$HOME/$(basename $local_mount)"
sshfs -o IdentityFile=$HOME/.ssh/id_rsa $1:/run/mount/$2 $local_mount 
