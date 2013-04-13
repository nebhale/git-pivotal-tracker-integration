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
    PivotalTracker::Client.stub!(:token, :use_ssl)

    $stdout = StringIO.new
    $stderr = StringIO.new
    @start = Start.new
  end

  before do
    PivotalConfiguration.should_receive(:project_id).and_return("test_project_id")

    @story = double("story")
    @stories = double("stories")
    @project = double("project")
    PivotalTracker::Project.should_receive(:find).and_return(@project)
  end

  it "should select a story directly if the argument is a number" do
    @project.should_receive(:stories).and_return(@stories)
    @stories.should_receive(:find).with(1)
    @start.should_receive(:print_info)
    @start.should_receive(:branch_name).and_return("dev_branch")
    @start.should_receive(:create_branch)
    @start.should_receive(:add_commit_hook)
    @start.should_receive(:start_on_tracker)

    @start.run("1")
  end

  it "should select a story of a type if the argument is a word" do
    menu = double("menu")
    menu.should_receive(:prompt=)

    @project.should_receive(:stories).and_return(@stories)
    @stories.should_receive(:all).with(
      :story_type => "feature",
      :current_state => ["unstarted", "unscheduled"],
      :limit => 5
    ).and_return([
      PivotalTracker::Story.new(:name => "name-1"),
      PivotalTracker::Story.new(:name => "name-2")
    ])

    menu.should_receive(:choice).with("name-1")
    menu.should_receive(:choice).with("name-2")

    @start.should_receive(:choose) { |&arg| arg.call menu }
    @start.should_receive(:print_info)
    @start.should_receive(:branch_name).and_return("dev_branch")
    @start.should_receive(:create_branch)
    @start.should_receive(:add_commit_hook)
    @start.should_receive(:start_on_tracker)

    @start.run("feature")
  end

  it "should select a story of all types if there is no argument" do
    menu = double("menu")
    menu.should_receive(:prompt=)

    @project.should_receive(:stories).and_return(@stories)
    @stories.should_receive(:all).with(
      :current_state => ["unstarted", "unscheduled"],
      :limit => 5
    ).and_return([
      PivotalTracker::Story.new(:story_type => "chore", :name => "name-1"),
      PivotalTracker::Story.new(:story_type => "bug", :name => "name-2")
    ])

    menu.should_receive(:choice).with("CHORE   name-1")
    menu.should_receive(:choice).with("BUG     name-2")

    @start.should_receive(:choose) { |&arg| arg.call menu }
    @start.should_receive(:print_info)
    @start.should_receive(:branch_name).and_return("dev_branch")
    @start.should_receive(:create_branch)
    @start.should_receive(:add_commit_hook)
    @start.should_receive(:start_on_tracker)

    @start.run(nil)
  end

  it "should print story information" do
    @start.should_receive(:story).and_return(@story)
    @story.should_receive(:name)
    @story.should_receive(:description).and_return("description-1\ndescription-2")
    PivotalTracker::Note.should_receive(:all).and_return([
      PivotalTracker::Note.new(:noted_at => Date.new, :text => "note-1")
    ])
    @start.should_receive(:branch_name).and_return("dev_branch")
    @start.should_receive(:create_branch)
    @start.should_receive(:add_commit_hook)
    @start.should_receive(:start_on_tracker)

    @start.run(nil)

    expect($stdout.string).to eq(
      "      Title: \n" +
      "Description: description-1\n" +
      "             description-2\n" +
      "     Note 1: note-1\n" +
      "\n")
  end

  it "should prompt for the development branch name" do
    @start.should_receive(:story).and_return(@story)
    @start.should_receive(:print_info)
    @story.should_receive(:id).twice.and_return("test_story_id")
    @start.should_receive(:ask).and_return("dev_branch")
    @start.should_receive(:create_branch)
    @start.should_receive(:add_commit_hook)
    @start.should_receive(:start_on_tracker)

    @start.run(nil)
  end

  it "should create the development branch" do
    @start.should_receive(:story).and_return(@story)
    @start.should_receive(:print_info)
    @start.should_receive(:branch_name).and_return("dev_branch")
    @start.should_receive(:current_branch).and_return("master")
    @start.should_receive(:exec).with("git pull --quiet --ff-only")
    @start.should_receive(:exec).with("git checkout --quiet -b dev_branch")
    PivotalConfiguration.should_receive(:merge_target=).with("master")
    @story.should_receive(:id).and_return("test_story_id")
    PivotalConfiguration.should_receive(:story_id=).with("test_story_id")
    @start.should_receive(:add_commit_hook)
    @start.should_receive(:start_on_tracker)

    @start.run(nil)
  end

  it "should not add a commit hook if it exists" do
    @start.should_receive(:story).and_return(@story)
    @start.should_receive(:print_info)
    @start.should_receive(:branch_name).and_return("dev_branch")
    @start.should_receive(:create_branch)
    Dir.should_receive(:pwd).and_return("spec")
    File.should_receive(:exist?).and_return(true)
    @start.should_receive(:start_on_tracker)

    @start.run(nil)
  end

  it "should add a commit hook if it does not exist" do
    @start.should_receive(:story).and_return(@story)
    @start.should_receive(:print_info)
    @start.should_receive(:branch_name).and_return("dev_branch")
    @start.should_receive(:create_branch)
    Dir.should_receive(:pwd).and_return("spec")
    File.should_receive(:exist?).and_return(false)
    @start.should_receive(:start_on_tracker)

    @start.run(nil)

    expect($stdout.string).to match(/OK/)
  end

  it "should start the story on Pivotral Tracker" do
    @start.should_receive(:story).and_return(@story)
    @start.should_receive(:print_info)
    @start.should_receive(:branch_name).and_return("dev_branch")
    @start.should_receive(:create_branch)
    @start.should_receive(:add_commit_hook)
    @story.should_receive(:update).with(:current_state => "started")

    @start.run(nil)

    expect($stdout.string).to match(/OK/)

  end
end
