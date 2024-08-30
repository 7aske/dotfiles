#!/usr/bin/env bash

color="${1###}"

r="${color:0:2}"
g="${color:2:2}"
b="${color:4:2}"

printf "R:%d G:%d B:%d\n" "0x$r" "0x$g" "0x$b"
