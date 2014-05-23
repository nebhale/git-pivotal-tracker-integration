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

require 'git-pivotal-tracker-integration/command/base'
require 'git-pivotal-tracker-integration/command/command'
require 'git-pivotal-tracker-integration/util/git'
require 'git-pivotal-tracker-integration/util/story'
require 'pivotal-tracker'

# The class that encapsulates starting a Pivotal Tracker Story
class GitPivotalTrackerIntegration::Command::Deliver < GitPivotalTrackerIntegration::Command::Base

  # Starts a Pivotal Tracker story by doing the following steps:
  # * Create a branch
  # * Add default commit hook
  # * Start the story on Pivotal Tracker
  #
  # @param [String, nil] filter a filter for selecting the story to start.  This
  #   filter can be either:
  #   * a story id
  #   * a story type (feature, bug, chore)
  #   * +nil+
  # @return [void]
  def run(filter)
    self.check_branch
    story = GitPivotalTrackerIntegration::Util::Story.select_release @project

    GitPivotalTrackerIntegration::Util::Story.pretty_print story

   current_branch = GitPivotalTrackerIntegration::Util::Git.branch_name

    GitPivotalTrackerIntegration::Util::Shell.exec "git checkout QA"
    if (GitPivotalTrackerIntegration::Util::Shell.exec "git merge -s recursive --strategy-option theirs develop")
      puts "Merged 'develop' in to 'QA'"
    else
      abort "FAILED to merge 'develop' in to 'QA'"
    end
    # GitPivotalTrackerIntegration::Util::Git.add_hook 'prepare-commit-msg', File.join(File.dirname(__FILE__), 'prepare-commit-msg.sh')

    # start_on_tracker story
  end

  def check_branch

      current_branch = GitPivotalTrackerIntegration::Util::Git.branch_name

      suggested_branch = "develop"

      if !suggested_branch.nil? && suggested_branch.length !=0 && current_branch != suggested_branch
          should_chage_branch = ask("Your currently checked out branch is '#{current_branch}'. Do you want to checkout '#{suggested_branch}' before starting?(Y/n)")
          if should_chage_branch != "n"
              print "Checking out branch '#{suggested_branch}'...\n\n"
              GitPivotalTrackerIntegration::Util::Shell.exec "git checkout --quiet #{suggested_branch}"
          else
              abort "You must be on the #{suggested_branch} branch to run this command."
          end

      end

  end

  private

  def development_branch_name(story)
      prefix = "#{story.id}-"
      story_name = "#{story.name.gsub(/[^0-9a-z\\s]/i, '_')}"
      if(story_name.length > 30)
          suggested_suffix = story_name[0..27]
          suggested_suffix << "__"
      else
          suggested_suffix = story_name
      end
      branch_name = "#{prefix}" + ask("Enter branch name (#{story.id}-<#{suggested_suffix}>): ")
      puts
      if branch_name == "#{prefix}"
          branch_name << suggested_suffix
      end
      branch_name.gsub(/[^0-9a-z\\s\-]/i, '_')
  end

  def start_on_tracker(story)
    print 'Starting story on Pivotal Tracker... '
    story.update(
      :current_state => 'started',
      :owned_by => GitPivotalTrackerIntegration::Util::Git.get_config('user.name')
    )
    puts 'OK'
  end

end
