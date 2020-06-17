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
require 'git-pivotal-tracker-integration/util/git'
require 'pivotal-tracker'

describe GitPivotalTrackerIntegration::Command::Configuration do

  before do
    $stdout = StringIO.new
    $stderr = StringIO.new
    @configuration = GitPivotalTrackerIntegration::Command::Configuration.new
  end

  it 'should not prompt the user for the API token if it is already configured' do
    GitPivotalTrackerIntegration::Util::Git.should_receive(:get_config).with('pivotal.api-token', :inherited).and_return('test_api_token')

    api_token = @configuration.api_token

    expect(api_token).to eq('test_api_token')
  end

  it 'should prompt the user for the API token if it is not configured' do
    GitPivotalTrackerIntegration::Util::Git.should_receive(:get_config).with('pivotal.api-token', :inherited).and_return('')
    @configuration.should_receive(:ask).and_return('test_api_token')
    GitPivotalTrackerIntegration::Util::Git.should_receive(:set_config).with('pivotal.api-token', 'test_api_token', :global)

    api_token = @configuration.api_token

    expect(api_token).to eq('test_api_token')
  end

  it 'should not prompt the user for the project if it is already configured' do
    project = double('project')
    GitPivotalTrackerIntegration::Util::Git.should_receive(:get_config).with('pivotal.project-id', :inherited).and_return('test_project_id')
    PivotalTracker::Project.should_receive(:find).with('test_project_id').and_return(project)

    expect(@configuration.project).to eq(project)
  end

  it 'should prompt the user for the project if it is not configured' do
    project = double('project')
    menu = double('menu')
    GitPivotalTrackerIntegration::Util::Git.should_receive(:get_config).with('pivotal.project-id', :inherited).and_return('')
    menu.should_receive(:prompt=)
    PivotalTracker::Project.should_receive(:all).and_return([
      PivotalTracker::Project.new(:id => 'id-2', :name => 'name-2'),
      PivotalTracker::Project.new(:id => 'id-1', :name => 'name-1')])
    menu.should_receive(:choice).with('name-1')
    menu.should_receive(:choice).with('name-2')
    @configuration.should_receive(:choose) { |&arg| arg.call menu }.and_return('test_project_id')
    GitPivotalTrackerIntegration::Util::Git.should_receive(:set_config).with('pivotal.project-id', 'test_project_id', :local)
    PivotalTracker::Project.should_receive(:find).with('test_project_id').and_return(project)

    expect(@configuration.project).to eq(project)
  end

  it 'should not prompt the user for his Pivotal Tracker user name if it is already configured' do
    user = 'User Name'
    GitPivotalTrackerIntegration::Util::Git.should_receive(:get_config).with('pivotal.user', :inherited).and_return(user)

    expect(@configuration.user).to eq(user)
  end

  it 'should prompt the user for his Pivotal Tracker user name if it is not configured' do
    user = 'User Name'
    menu = double('menu')
    projects = [double('project')]
    users = [[user]]
    GitPivotalTrackerIntegration::Util::Git.should_receive(:get_config).with('pivotal.user', :inherited).and_return('')
    menu.should_receive(:prompt=)
    PivotalTracker::Project.should_receive(:all).and_return(projects)
    projects.should_receive(:map).and_return(users)
    menu.should_receive(:choice).with(user)
    @configuration.should_receive(:choose) { |&arg| arg.call menu }.and_return(user)
    GitPivotalTrackerIntegration::Util::Git.should_receive(:set_config).with('pivotal.user', user.inspect, :local)

    expect(@configuration.user).to eq(user)
  end

  it 'should persist the story when requested' do
    GitPivotalTrackerIntegration::Util::Git.should_receive(:set_config).with('pivotal-story-id', 12345678, :branch)

    @configuration.story = PivotalTracker::Story.new(:id => 12345678)
  end

  it 'should return a story when requested' do
    story_id = '12345678'
    project = double('project')
    stories = double('stories')
    story = double('story')
    GitPivotalTrackerIntegration::Util::Git.should_receive(:get_config).with('pivotal-story-id', :branch).and_return(story_id)
    @configuration.should_receive(:project).and_return(project)
    project.should_receive(:stories).and_return(stories)
    stories.should_receive(:find).with(story_id).and_return(story)

    expect(@configuration.story).to be(story)
  end

  it 'should abort when story is requested but no branch is started' do
    GitPivotalTrackerIntegration::Util::Git.should_receive(:get_config).with('pivotal-story-id', :branch).and_return("")
    lambda { @configuration.story }.should raise_error SystemExit
  end

end
