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

# The class that encapsulates finishing a Pivotal Tracker Story
class GitPivotalTrackerIntegration::Command::Finish < GitPivotalTrackerIntegration::Command::Base

  # Finishes a Pivotal Tracker story by doing the following steps:
  # * Check that the pending merge will be trivial
  # * Merge the development branch into the root branch
  # * Delete the development branch
  # * Push changes to remote
  #
  # @return [void]
  def run(argument)
    $LOG.debug("#{self.class} in project:#{@project.name} pwd:#{(GitPivotalTrackerIntegration::Util::Shell.exec 'pwd').chop} branch:#{GitPivotalTrackerIntegration::Util::Git.branch_name}")
    no_complete = argument =~ /--no-complete/
    
    branch_status_check = GitPivotalTrackerIntegration::Util::Shell.exec "git status -s"
    abort "\n\nThere are some unstaged changes in your current branch. Please do execute the below commands first and then try with git finish \n git add . \n git commit -m '<your-commit-message>'" unless branch_status_check.empty?

    # ask("pause")
    GitPivotalTrackerIntegration::Util::Git.trivial_merge?
    $LOG.debug("configuration:#{@configuration}")
    $LOG.debug("project:#{@project}")
    $LOG.debug("story:#{@configuration.story(@project)}")
    memm =  PivotalTracker::Membership.all(@project)
    self.commit_new_build
    time_spent = ""
    while 1
      time_spent = ask("How much time did you spend on this task? (example: 15m, 2.5h)")
      if (/\d/.match( time_spent )) && /[mhd]/.match(time_spent)
        break
      end
    end
    finish_toggle(@configuration, time_spent)
    GitPivotalTrackerIntegration::Util::Git.merge(@configuration.story(@project), no_complete)
    GitPivotalTrackerIntegration::Util::Git.push GitPivotalTrackerIntegration::Util::Git.branch_name
  end


def commit_new_build
  # Update version and build numbers
  build_number = Time.now.utc.strftime("%y%m%d-%H%M")

  puts "build_number:#{build_number}"
  project_directory = ((GitPivotalTrackerIntegration::Util::Shell.exec 'find . -name "*.xcodeproj" 2>/dev/null').split /\/(?=[^\/]*$)/)[0]
  if project_directory.nil?
    return
  end
  working_directory = (GitPivotalTrackerIntegration::Util::Shell.exec "pwd").chop
  puts "working_directory:#{working_directory}*"

  # cd to the project_directory
  Dir.chdir(project_directory)

  # set build number and project number in project file
  GitPivotalTrackerIntegration::Util::Shell.exec "pwd"
  puts GitPivotalTrackerIntegration::Util::Shell.exec "xcrun agvtool new-version -all #{build_number}", false
  puts GitPivotalTrackerIntegration::Util::Shell.exec "xcrun agvtool new-marketing-version SNAPSHOT"

  # cd back to the working_directory
  Dir.chdir(working_directory)

  # Create a new build commit, push to develop
  GitPivotalTrackerIntegration::Util::Git.create_commit( "Update build number to #{build_number}", @configuration.story(@project))
end
end
