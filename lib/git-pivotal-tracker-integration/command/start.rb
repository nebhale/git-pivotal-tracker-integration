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
class GitPivotalTrackerIntegration::Command::Start < GitPivotalTrackerIntegration::Command::Base

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
    story = GitPivotalTrackerIntegration::Util::Story.select_story @project, filter

    GitPivotalTrackerIntegration::Util::Story.pretty_print story

    GitPivotalTrackerIntegration::Util::Git.checkout "development"
    GitPivotalTrackerIntegration::Util::Git.create_branch development_branch_name story
    @configuration.story = story

    GitPivotalTrackerIntegration::Util::Git.add_hook 'prepare-commit-msg', File.join(File.dirname(__FILE__), 'prepare-commit-msg.sh')

    start_on_tracker story
  end

  private

  def development_branch_name(story)
    branch_title = (story.name.gsub(/[ '":;#{}]/, '-')).downcase
    "#{story.id}-#{branch_title}"
  end

  def start_on_tracker(story)
    username = @configuration.username
    state = 'started'
    print 'Starting story on Pivotal Tracker... '

    # If the story needs an estimate, but it doesn't have one, ask for it
    if story.story_type == 'feature' and story.estimate <= 0
      estimate = ask("Enter number of points: ")
      story.update(
        :current_state => state,
        :owned_by => username,
        :estimate => estimate
      )
    else
      story.update(
        :current_state => state,
        :owned_by => username
      )
    end
    puts 'OK'
  end

end
