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
require "git-pivotal-tracker-integration/start"

describe Start do

  before do
    PivotalConfiguration.should_receive(:api_token).and_return("test_api_token")
    PivotalConfiguration.should_receive(:project_id).and_return("test_project_id")
    PivotalTracker::Client.stub!(:token, :use_ssl)

    $stdout = StringIO.new
    $stderr = StringIO.new
  end

  it "should select a story directly if the argument is a number" do
    project = double("project")
    stories = double("stories")
    PivotalTracker::Project.should_receive(:find).and_return(project)
    project.should_receive(:stories).and_return(stories)
    stories.should_receive(:find).with(1)

    Start.new(["1"])
  end

  it "should prompt the user for stories of a type if the argument is a word" do
    project = double("project")
    stories = double("stories")
    PivotalTracker::Project.should_receive(:find).and_return(project)
    project.should_receive(:stories).and_return(stories)
    stories.should_receive(:all).with(
      :story_type => "a",
      :current_state => ["unstarted", "unscheduled"],
      :limit => 5
    ).and_return([
      PivotalTracker::Story.new(:name => "name-1"),
      PivotalTracker::Story.new(:name => "name-2")])

    menu = double("menu")
    menu.should_receive(:prompt=)
    menu.should_receive(:choice).with("name-1")
    menu.should_receive(:choice).with("name-2")

    Start.any_instance.should_receive(:choose) { |&arg| arg.call menu }

    Start.new(["a"])
  end

  it "should prompt the user for stories if there is no argument" do
    project = double("project")
    stories = double("stories")
    PivotalTracker::Project.should_receive(:find).and_return(project)
    project.should_receive(:stories).and_return(stories)
    stories.should_receive(:all).with(
      :current_state => ["unstarted", "unscheduled"],
      :limit => 5
    ).and_return([
      PivotalTracker::Story.new(:name => "name-1", :story_type => "type-1"),
      PivotalTracker::Story.new(:name => "name-2", :story_type => "type-2")])

    menu = double("menu")
    menu.should_receive(:prompt=)
    menu.should_receive(:choice).with("TYPE-1  name-1")
    menu.should_receive(:choice).with("TYPE-2  name-2")

    Start.any_instance.should_receive(:choose) { |&arg| arg.call menu }

    Start.new([])
  end

  it "should fail if pull fails" do
    project = double("project")
    stories = double("stories")
    story = double("story")
    PivotalTracker::Project.should_receive(:find).and_return(project)
    project.should_receive(:stories).and_return(stories)
    stories.should_receive(:find).and_return(story)
    story.should_receive(:name)
    story.should_receive(:description).and_return("description-1\ndescription-2")
    PivotalTracker::Note.should_receive(:all).and_return([
      PivotalTracker::Note.new(:noted_at => Date.new, :text => "text")])
    story.should_receive(:id).twice.and_return("1")

    start = Start.new(["1"])
    start.should_receive(:`).with("git branch").and_return("   master\n * test_branch")
    start.should_receive(:ask).and_return("test_branch")
    start.should_receive(:`).with("git pull --quiet --ff-only")
    $?.should_receive(:exitstatus).and_return(-1)

    lambda { start.run }.should raise_error(SystemExit)
  end

  it "should fail if branch creation fails" do
    project = double("project")
    stories = double("stories")
    PivotalTracker::Project.should_receive(:find).and_return(project)
    project.should_receive(:stories).and_return(stories)
    stories.should_receive(:find).with(1)
    Start.any_instance.should_receive(:print_info)
    Start.any_instance.should_receive(:branch_name).and_return("test_branch")
    Start.any_instance.should_receive(:current_branch).and_return("current_branch")

    start = Start.new(["1"])
    start.should_receive(:`).with("git pull --quiet --ff-only")
    $?.should_receive(:exitstatus).and_return(0)
    start.should_receive(:`).with("git checkout --quiet -b test_branch")
    $?.should_receive(:exitstatus).and_return(-1)

    lambda { start.run }.should raise_error(SystemExit)
  end

  it "should fail if merge target cannot be set" do
    project = double("project")
    stories = double("stories")
    PivotalTracker::Project.should_receive(:find).and_return(project)
    project.should_receive(:stories).and_return(stories)
    stories.should_receive(:find).with(1)
    Start.any_instance.should_receive(:print_info)
    Start.any_instance.should_receive(:branch_name).and_return("test_branch")
    Start.any_instance.should_receive(:current_branch).and_return("current_branch")

    start = Start.new(["1"])
    start.should_receive(:`).with("git pull --quiet --ff-only")
    $?.should_receive(:exitstatus).and_return(0)
    start.should_receive(:`).with("git checkout --quiet -b test_branch")
    $?.should_receive(:exitstatus).and_return(0)
    PivotalConfiguration.should_receive(:merge_target=)
    $?.should_receive(:exitstatus).and_return(-1)

    lambda { start.run }.should raise_error(SystemExit)
  end

  it "should fail if merge story id cannot be set" do
    project = double("project")
    stories = double("stories")
    story = double("story")
    PivotalTracker::Project.should_receive(:find).and_return(project)
    project.should_receive(:stories).and_return(stories)
    stories.should_receive(:find).with(1).and_return(story)
    Start.any_instance.should_receive(:print_info)
    Start.any_instance.should_receive(:branch_name).and_return("test_branch")
    Start.any_instance.should_receive(:current_branch).and_return("current_branch")

    start = Start.new(["1"])
    start.should_receive(:`).with("git pull --quiet --ff-only")
    $?.should_receive(:exitstatus).and_return(0)
    start.should_receive(:`).with("git checkout --quiet -b test_branch")
    $?.should_receive(:exitstatus).and_return(0)
    PivotalConfiguration.should_receive(:merge_target=)
    $?.should_receive(:exitstatus).and_return(0)
    story.should_receive(:id)
    PivotalConfiguration.should_receive(:story_id=)
    $?.should_receive(:exitstatus).and_return(-1)

    lambda { start.run }.should raise_error(SystemExit)
  end

  it "should not fail" do
    project = double("project")
    stories = double("stories")
    story = double("story")
    PivotalTracker::Project.should_receive(:find).and_return(project)
    project.should_receive(:stories).and_return(stories)
    stories.should_receive(:find).with(1).and_return(story)
    Start.any_instance.should_receive(:print_info)
    Start.any_instance.should_receive(:branch_name).and_return("test_branch")
    Start.any_instance.should_receive(:current_branch).and_return("current_branch")

    start = Start.new(["1"])
    start.should_receive(:`).with("git pull --quiet --ff-only")
    $?.should_receive(:exitstatus).and_return(0)
    start.should_receive(:`).with("git checkout --quiet -b test_branch")
    $?.should_receive(:exitstatus).and_return(0)
    PivotalConfiguration.should_receive(:merge_target=)
    $?.should_receive(:exitstatus).and_return(0)
    story.should_receive(:id)
    PivotalConfiguration.should_receive(:story_id=)
    $?.should_receive(:exitstatus).and_return(0)
    Dir.should_receive(:pwd).and_return("spec")
    File.should_receive(:exist?).and_return(false)
    story.should_receive(:update).with(:current_state => "started")

    start.run
  end

end
