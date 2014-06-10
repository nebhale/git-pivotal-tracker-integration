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
    @toggl.debug_on
    $LOG.debug("#{self.class} in project:#{@project.name} pwd:#{(GitPivotalTrackerIntegration::Util::Shell.exec 'pwd').chop} branch:#{GitPivotalTrackerIntegration::Util::Git.branch_name}")
    no_complete = argument =~ /--no-complete/
    time_spent = ask("How much time did you spend on this task? (example: 15m, 2.5h)")
    finish_toggle(@configuration, time_spent)
    # ask("pause")
    GitPivotalTrackerIntegration::Util::Git.trivial_merge?
    $LOG.debug("configuration:#{@configuration}")
    $LOG.debug("project:#{@project}")
    $LOG.debug("story:#{@configuration.story(@project)}")
    GitPivotalTrackerIntegration::Util::Git.merge(@configuration.story(@project), no_complete)
    GitPivotalTrackerIntegration::Util::Git.push GitPivotalTrackerIntegration::Util::Git.branch_name
  end



end
