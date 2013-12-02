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
require 'git-pivotal-tracker-integration/util/label'
require 'pivotal-tracker'

MODES = %w(add remove list once)

# The class that encapsulates starting a Pivotal Tracker Story
class GitPivotalTrackerIntegration::Command::Label < GitPivotalTrackerIntegration::Command::Base

  # Adds labels for active story.
  # @return [void]
  def run(mode, *labels)
    story = @configuration.story(@project)
    abort "You need to specify mode first [#{MODES}], e.g. 'git label add to_qa'" unless MODES.include? mode
    abort "You need to be on started story branch to add label to it!" if story.nil?

    GitPivotalTrackerIntegration::Util::Label.send(mode, story, *labels)
  end
end
