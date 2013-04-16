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

require "git-pivotal-tracker-integration/util/util"

# Utilties for dealing with the shell
class GitPivotalTrackerIntegration::Util::Shell

  # Executes a command.  If the command's +Status#existstatus+ is not +0+,
  # then +Kernel::abort+ is called with +FAIL+ as the message.
  #
  # @param command [String] the command to execute
  # @return [String] the result of the command
  def self.exec(command)
    result = `#{command}`
    if $?.exitstatus != 0
      abort "FAIL"
    end

    result
  end

end
