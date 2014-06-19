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
require 'git-pivotal-tracker-integration/version-update/gradle'

# The class that encapsulates releasing a Pivotal Tracker Story
class GitPivotalTrackerIntegration::Command::Release < GitPivotalTrackerIntegration::Command::Base

  # Releases a Pivotal Tracker story by doing the following steps:
  # * Update the version to the release version
  # * Create a tag for the release version
  # * Update the version to the new development version
  # * Push tag and changes to remote
  #
  # @param [String, nil] filter a filter for selecting the release to start.  This
  #   filter can be either:
  #   * a story id
  #   * +nil+
  # @return [void]
  def run(filter)
    $LOG.debug("#{self.class} in project:#{@project.name} pwd:#{(GitPivotalTrackerIntegration::Util::Shell.exec 'pwd').chop} branch:#{GitPivotalTrackerIntegration::Util::Git.branch_name}")
    story = GitPivotalTrackerIntegration::Util::Story.select_release(@project, filter.nil? ? 'v' : filter)
    GitPivotalTrackerIntegration::Util::Story.pretty_print story
    $LOG.debug("story:#{story.name}")

    current_branch = GitPivotalTrackerIntegration::Util::Git.branch_name

    # checkout QA branch
    # Update QA from origin    
    puts GitPivotalTrackerIntegration::Util::Shell.exec "git checkout QA"
    puts GitPivotalTrackerIntegration::Util::Shell.exec "git fetch"
    puts GitPivotalTrackerIntegration::Util::Shell.exec "git merge -s recursive --strategy-option theirs origin QA"

    # checkout master branch
    # Merge QA into master
    puts GitPivotalTrackerIntegration::Util::Shell.exec "git checkout master"
       puts GitPivotalTrackerIntegration::Util::Shell.exec "git fetch"
    if (GitPivotalTrackerIntegration::Util::Shell.exec "git merge -s recursive --strategy-option theirs QA")
      puts "Merged 'QA' in to 'master'"
    else
      abort "FAILED to merge 'QA' in to 'master'"
    end

    # Update version and build numbers
    version_number = story.name.dup
    version_number[0] = ""
    puts "storyNAME:#{story.name}"
    puts "version_number:#{version_number}"
    project_directory = ((GitPivotalTrackerIntegration::Util::Shell.exec 'find . -name "*.xcodeproj" 2>/dev/null').split /\/(?=[^\/]*$)/)[0]
    working_directory = (GitPivotalTrackerIntegration::Util::Shell.exec "pwd").chop
    puts "working_directory:#{working_directory}*"
    
    # cd to the project_directory
    Dir.chdir(project_directory)

    # set project number in project file
    GitPivotalTrackerIntegration::Util::Shell.exec "pwd"   
    puts GitPivotalTrackerIntegration::Util::Shell.exec "xcrun agvtool new-marketing-version #{version_number}"

    # cd back to the working_directory
    Dir.chdir(working_directory)

    # Create a new build commit, push to QA, checkout develop
    puts GitPivotalTrackerIntegration::Util::Git.create_commit( "Update version number to #{version_number} for delivery to QA", story)
    puts GitPivotalTrackerIntegration::Util::Shell.exec "git push" 
    puts GitPivotalTrackerIntegration::Util::Shell.exec "git checkout #{current_branch}"

    s_labels_string = story.labels
    s_labels = ""
    if (s_labels_string)
      s_labels = s_labels_string.split(",")
      s_labels << story.name
      s_labels_string = s_labels.uniq.join(",")
    else
      s_labels_string = story.name
    end

    puts "labels:#{s_labels_string}"
    story.update(:labels => s_labels_string)

  end



end
