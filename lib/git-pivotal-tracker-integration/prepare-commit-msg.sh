#!/usr/bin/env bash

CURRENT_BRANCH=$(git branch | grep "*" | sed "s/* //")
STORY_ID=$(git config branch.$CURRENT_BRANCH.pivotal-story-id)

if [[ -n $STORY_ID ]]; then
	ORIG_MSG_FILE="$1"
	TEMP=$(mktemp /tmp/git-XXXXX)

	(printf "\n\n[#$STORY_ID]" ; cat "$1") > "$TEMP"
	cat "$TEMP" > "$ORIG_MSG_FILE"
fi
