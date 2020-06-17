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
require 'git-pivotal-tracker-integration/command/assign'
require 'git-pivotal-tracker-integration/util/git'
require 'pivotal-tracker'

describe GitPivotalTrackerIntegration::Command::Assign do

  before do
    $stdout = StringIO.new
    $stderr = StringIO.new

    @project = double('project')
    @story = double('story')
    GitPivotalTrackerIntegration::Util::Git.should_receive(:repository_root)
    GitPivotalTrackerIntegration::Command::Configuration.any_instance.should_receive(:api_token)
    GitPivotalTrackerIntegration::Command::Configuration.any_instance.should_receive(:project_id)
    PivotalTracker::Project.should_receive(:find).and_return(@project)
    @assign = GitPivotalTrackerIntegration::Command::Assign.new
  end

  it 'should run' do
    GitPivotalTrackerIntegration::Command::Configuration.any_instance.should_receive(:story).and_return(@story)

    menu = double('menu')
    menu.should_receive(:prompt=)
    menu.should_receive(:choice).with('Username')

    @assign.should_receive(:choose) { |&arg| arg.call menu }.and_return('Username')

    memberships = double('memberships')
    membership = double('membership')
    @project.should_receive(:memberships).and_return(memberships)
    memberships.should_receive(:all).and_return([membership])
    membership.should_receive(:name).and_return('Username')
    GitPivotalTrackerIntegration::Util::Story.should_receive(:assign).with(@story, 'Username')

    @assign.run(nil)
  end
end
