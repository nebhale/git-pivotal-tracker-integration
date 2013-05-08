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

require 'spec_helper'
require 'git-pivotal-tracker-integration/command/configuration'
require 'git-pivotal-tracker-integration/command/finish'
require 'git-pivotal-tracker-integration/util/git'
require 'pivotal-tracker'

describe GitPivotalTrackerIntegration::Command::Finish do

  before do
    $stdout = StringIO.new
    $stderr = StringIO.new

    @project = double('project')
    GitPivotalTrackerIntegration::Util::Git.should_receive(:repository_root)
    GitPivotalTrackerIntegration::Command::Configuration.any_instance.should_receive(:api_token)
    GitPivotalTrackerIntegration::Command::Configuration.any_instance.should_receive(:project_id)
    PivotalTracker::Project.should_receive(:find).and_return(@project)
    @finish = GitPivotalTrackerIntegration::Command::Finish.new
  end

  it 'should run' do
    GitPivotalTrackerIntegration::Util::Git.should_receive(:trivial_merge?)
    GitPivotalTrackerIntegration::Command::Configuration.any_instance.should_receive(:story)
    GitPivotalTrackerIntegration::Util::Git.should_receive(:merge)
    GitPivotalTrackerIntegration::Util::Git.should_receive(:branch_name).and_return('master')
    GitPivotalTrackerIntegration::Util::Git.should_receive(:push).with('master')

    @finish.run nil
  end
end
