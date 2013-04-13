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

require "spec_helper"
require "git-pivotal-tracker-integration/pivotal_configuration"

describe PivotalConfiguration do
  before do
    $stdout = StringIO.new
  end

  it "should not prompt the user for the API token if it is already configured" do
    PivotalConfiguration.should_receive(:`).with("git config pivotal.api-token").and_return("test_api_token")

    api_token = PivotalConfiguration.api_token

    expect(api_token).to eq("test_api_token")
  end

  it "should prompt the user for the API token if it is not configured (nil)" do |variable|
    PivotalConfiguration.should_receive(:`).with("git config pivotal.api-token").and_return(nil)
    PivotalConfiguration.should_receive(:ask).and_return("test_api_token")
    PivotalConfiguration.should_receive(:`).with("git config --global pivotal.api-token test_api_token")

    api_token = PivotalConfiguration.api_token

    expect(api_token).to eq("test_api_token")
  end

  it "should prompt the user for the API token if it is not configured (empty)" do |variable|
    PivotalConfiguration.should_receive(:`).with("git config pivotal.api-token").and_return("")
    PivotalConfiguration.should_receive(:ask).and_return("test_api_token")
    PivotalConfiguration.should_receive(:`).with("git config --global pivotal.api-token test_api_token")

    api_token = PivotalConfiguration.api_token

    expect(api_token).to eq("test_api_token")
  end

  it "should return the configured merge_remote" do
    PivotalConfiguration.stub(:merge_target).and_return("test_merge_target")
    PivotalConfiguration.should_receive(:`).with("git config branch.test_merge_target.remote").and_return("test_merge_remote")

    merge_remote = PivotalConfiguration.merge_remote

    expect(merge_remote).to eq("test_merge_remote")
  end

  it "should return the configured merge_target" do
    PivotalConfiguration.should_receive(:`).with("git branch").and_return("   master\n * test_branch")
    PivotalConfiguration.should_receive(:`).with("git config branch.test_branch.pivotal-merge-target").and_return("test_merge_target")

    merge_target = PivotalConfiguration.merge_target

    expect(merge_target).to eq("test_merge_target")
  end

  it "should configure the merge_target in the local configuration" do
    PivotalConfiguration.should_receive(:`).with("git branch").and_return("   master\n * test_branch")
    PivotalConfiguration.should_receive(:`).with("git config --local branch.test_branch.pivotal-merge-target test_merge_target")

    PivotalConfiguration.merge_target = "test_merge_target"
  end

  it "should return the configured story_id" do
    PivotalConfiguration.should_receive(:`).with("git branch").and_return("   master\n * test_branch")
    PivotalConfiguration.should_receive(:`).with("git config branch.test_branch.pivotal-story-id").and_return("test_story_id")

    story_id = PivotalConfiguration.story_id

    expect(story_id).to eq("test_story_id")
  end

  it "should configure the story_id in the local configuration" do
    PivotalConfiguration.should_receive(:`).with("git branch").and_return("   master\n * test_branch")
    PivotalConfiguration.should_receive(:`).with("git config --local branch.test_branch.pivotal-story-id test_story_id")

    PivotalConfiguration.story_id = "test_story_id"
  end

  it "should not prompt the user for the project id if it is already configured" do
    PivotalConfiguration.should_receive(:`).with("git config pivotal.project-id").and_return("test_project_id")

    project_id = PivotalConfiguration.project_id

    expect(project_id).to eq("test_project_id")
  end

  it "should prompt the user for the project id if it is not configured (nil)" do |variable|
    PivotalConfiguration.should_receive(:`).with("git config pivotal.project-id").and_return(nil)
    PivotalConfiguration.should_receive(:choose).and_return("test_project_id")
    PivotalConfiguration.should_receive(:`).with("git config --local pivotal.project-id test_project_id")

    project_id = PivotalConfiguration.project_id

    expect(project_id).to eq("test_project_id")
  end

  it "should prompt the user for the project id if it is not configured (empty)" do |variable|
    PivotalConfiguration.should_receive(:`).with("git config pivotal.project-id").and_return("")
    PivotalConfiguration.should_receive(:choose).and_return("test_project_id")
    PivotalConfiguration.should_receive(:`).with("git config --local pivotal.project-id test_project_id")

    project_id = PivotalConfiguration.project_id

    expect(project_id).to eq("test_project_id")
  end

  it "should populate a menu with all projects" do
    PivotalConfiguration.should_receive(:`).with("git config pivotal.project-id").and_return("")
    PivotalTracker::Project.should_receive(:all).and_return([
      PivotalTracker::Project.new(:id => "id-2", :name => "name-2"),
      PivotalTracker::Project.new(:id => "id-1", :name => "name-1")])

    menu = double("menu")
    menu.should_receive(:prompt=)
    menu.should_receive(:choice).with("name-1")
    menu.should_receive(:choice).with("name-2")

    PivotalConfiguration.should_receive(:choose) { |&arg| arg.call menu }.and_return("test_project_id")
    PivotalConfiguration.should_receive(:`).with("git config --local pivotal.project-id test_project_id")

    PivotalConfiguration.project_id
  end

end
