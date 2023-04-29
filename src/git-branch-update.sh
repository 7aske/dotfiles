#!/usr/bin/bash

set -e

SRC_BRANCH="${SCR_BRANCH:-$(git branch --show-current)}"

[ -z "$SRC_BRANCH" ] && echo "No source branch found" && exit 1

DEST_BRANCH="${DEST_BRANCH:-$1}"

[ -z "$DEST_BRANCH" ] && echo "No destination branch provided" && exit 1

git checkout "$DEST_BRANCH" \
	&& git pull \
	&& git merge "$SRC_BRANCH" \
	&& git push \
	&& git checkout "$SRC_BRANCH"
