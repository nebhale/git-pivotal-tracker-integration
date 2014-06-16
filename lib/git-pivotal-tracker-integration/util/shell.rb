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

require 'git-pivotal-tracker-integration/util/util'

# Utilities for dealing with the shell
class GitPivotalTrackerIntegration::Util::Shell

  # Executes a command
  #
  # @param [String] command the command to execute
  # @param [Boolean] abort_on_failure whether to +Kernel#abort+ with +FAIL+ as
  #   the message when the command's +Status#existstatus+ is not +0+
  # @return [String] the result of the command
  def self.exec(command, abort_on_failure = true)
    result = `#{command}`
    if $?.exitstatus != 0 && abort_on_failure
      abort "FAIL on command:#{command}"
    end

    result
  end

end
