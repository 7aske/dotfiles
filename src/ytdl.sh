#!/usr/bin/env bash

for video in $(cat "$1"); do
    yt-dlp -x $video --audio-format mp3
done
