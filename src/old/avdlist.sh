#!/bin/sh

dir="$HOME/.android/avd/"

find "$dir" -maxdepth 1 -name "*.ini" -exec basename {} .ini \;
