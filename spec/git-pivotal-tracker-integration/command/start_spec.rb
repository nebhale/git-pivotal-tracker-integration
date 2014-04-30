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
require 'git-pivotal-tracker-integration/command/start'
require 'git-pivotal-tracker-integration/util/git'
require 'git-pivotal-tracker-integration/util/story'
require 'pivotal-tracker'

describe GitPivotalTrackerIntegration::Command::Start do

  before do
    $stdout = StringIO.new
    $stderr = StringIO.new

    @project = double('project')
    @story = double('story')
    GitPivotalTrackerIntegration::Util::Git.should_receive(:repository_root)
    GitPivotalTrackerIntegration::Command::Configuration.any_instance.should_receive(:api_token)
    GitPivotalTrackerIntegration::Command::Configuration.any_instance.should_receive(:project_id)
    PivotalTracker::Project.should_receive(:find).and_return(@project)
    @start = GitPivotalTrackerIntegration::Command::Start.new
  end

  it 'should run' do
    GitPivotalTrackerIntegration::Util::Story.should_receive(:select_story).with(@project, 'test_filter').and_return(@story)
    GitPivotalTrackerIntegration::Util::Story.should_receive(:pretty_print)
    @story.should_receive(:id).twice.and_return(12345678)
    @start.should_receive(:ask).and_return('development_branch')
    @story.stub(:name).and_return("development_branch")
    GitPivotalTrackerIntegration::Util::Git.should_receive(:create_branch).with('12345678-development_branch')
    GitPivotalTrackerIntegration::Command::Configuration.any_instance.should_receive(:story=)
    GitPivotalTrackerIntegration::Util::Git.should_receive(:add_hook)
    GitPivotalTrackerIntegration::Util::Git.should_receive(:get_config).with('user.name').and_return('test_owner')
    @story.should_receive(:update).with(
      :current_state => 'started',
      :owned_by => 'test_owner'
    )

    @start.run 'test_filter'
  end
end
