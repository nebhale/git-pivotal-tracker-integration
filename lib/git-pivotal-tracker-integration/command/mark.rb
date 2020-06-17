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

# The class that encapsulates assigning current Pivotal Tracker Story to a user
class GitPivotalTrackerIntegration::Command::Mark < GitPivotalTrackerIntegration::Command::Base
  STATES = %w(unstarted started finished delivered rejected accepted)

  # Assigns story to user.
  # @return [void]
  def run(state)
    state = choose_state if state.nil? or !STATES.include?(state)

    GitPivotalTrackerIntegration::Util::Story.mark(@configuration.story, state)
  end

  private

  def choose_state
    choose do |menu|
      menu.prompt = 'Choose story state from above list: '
      STATES.each do |state|
        menu.choice(state)
      end
    end
  end
end
