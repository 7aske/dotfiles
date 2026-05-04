#!/usr/bin/env bash

if [ -z "$1" ]; then
	echo "fatal: Repository name not specified"
	exit 1
fi

REPO="$1.git"
GIT_DIR="/srv/git"
GIT_HOME="/home/git/repo"

if [ -e "$GIT_DIR/$REPO" ]; then
	echo "fatal: Repository '$REPO' already exists"
	exit 1
fi

sudo -u git mkdir "$GIT_DIR/$REPO"
sudo -u git ln -sf "$GIT_DIR/$REPO" "$GIT_HOME/$REPO"
sudo -u git git -C "$GIT_DIR/$REPO" init --bare

