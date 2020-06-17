#!/usr/bin/env bash
# Git Pivotal Tracker Integration
# Copyright (c) 2013 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
STORY_ID=$(git config branch.$CURRENT_BRANCH.pivotal-story-id)

if [[ $2 != "commit" && -n $STORY_ID ]]; then
 ORIG_MSG_FILE="$1"
 TEMP="/tmp/git-$RANDOM"

 (printf "\n\n[#$STORY_ID]" ; cat "$1") > "$TEMP"
 cat "$TEMP" > "$ORIG_MSG_FILE"
fi