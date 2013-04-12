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

require "git-pivotal-tracker-integration/base"

class Finish < Base

  def run
    development_branch = current_branch
    merge_remote = PivotalConfiguration.merge_remote
    merge_target_branch = PivotalConfiguration.merge_target
    story_id = PivotalConfiguration.story_id

    check_trivial_merge development_branch, merge_target_branch, merge_remote
    merge_branch development_branch, merge_target_branch, story_id
    delete_branch development_branch
    push merge_remote
  end

  private

  def check_trivial_merge(development_branch, merge_target_branch, merge_remote)

    print "Checking for trivial merge from #{development_branch} to #{merge_target_branch}... "
    `git fetch #{merge_remote}`
    if $?.exitstatus != 0
      abort "FAIL"
    end

    remote_tip = `git rev-parse #{merge_remote}/#{merge_target_branch}`
    if $?.exitstatus != 0
      abort "FAIL"
    end

    local_tip = `git rev-parse #{merge_target_branch}`
    if $?.exitstatus != 0
      abort "FAIL"
    end

    if remote_tip != local_tip
      abort "FAIL"
    end

    common_ancestor = `git merge-base #{merge_target_branch} #{development_branch}`
    if $?.exitstatus != 0
      abort "FAIL"
    end

    if local_tip != common_ancestor
      abort "FAIL"
    else
      puts "OK"
    end

  end

  def merge_branch(development_branch, merge_target_branch, story_id)
    print "Merging #{development_branch} to #{merge_target_branch}... "

    `git checkout --quiet #{merge_target_branch}`
    if $?.exitstatus != 0
      abort "FAIL"
    end

    `git merge --quiet --no-ff -m "Merge #{development_branch} to #{merge_target_branch}\n\n[Completes ##{story_id}]" #{development_branch}`
    if $?.exitstatus != 0
      abort "FAIL"
    else
      puts "OK"
    end

  end

  def delete_branch(development_branch)
    print "Deleting #{development_branch}... "

    `git branch -D #{development_branch}`
    if $?.exitstatus != 0
      abort "FAIL"
    else
      puts "OK"
    end
  end

  def push(merge_remote)
    print "Pushing to #{merge_remote}... "
    `git push --quiet #{merge_remote}`
    if $?.exitstatus != 0
      abort "FAIL"
    else
      puts "OK"
    end
  end
end
