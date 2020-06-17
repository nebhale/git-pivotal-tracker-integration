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
require 'git-pivotal-tracker-integration/util/label'
require 'pivotal-tracker'

describe GitPivotalTrackerIntegration::Util::Label do

  before do
    $stdout = StringIO.new
    $stderr = StringIO.new

    @project = double('project')
    @stories = double('stories')
    @story = double('story')
    @menu = double('menu')
  end

  it 'should add labels to story' do
    old_labels = 'other_label'
    @story.should_receive(:labels).and_return(old_labels)
    @story.should_receive(:update).with(:labels => ["other_label", "on_qa"]).and_return(true)
    @story.should_receive(:name)

    GitPivotalTrackerIntegration::Util::Label.add(@story, 'on_qa')
  end

  it 'should add unique labels to story' do
    PivotalTracker::Project.should_receive(:find).and_return(@project)
    project_id = 123
    other_story = double(:other_story)
    @story.should_receive(:project_id).and_return(project_id)
    @project.should_receive(:stories).and_return(@stories)
    @stories.should_receive(:all).and_return([@story, other_story])
    @story.should_receive(:name).exactly(4).times.and_return('name')
    other_story.should_receive(:name).exactly(2).times.and_return('other_name')
    @story.should_receive(:labels).and_return('other_label')
    other_story.should_receive(:labels).exactly(3).times.and_return('on_qa')
    other_story.should_receive(:update).and_return(true)
    @story.should_receive(:update).with(:labels => ["other_label", "on_qa"]).and_return(true)
    GitPivotalTrackerIntegration::Util::Label.once(@story, 'on_qa')
  end

  it 'should abort when cannot add labels to story' do
    old_labels = 'other_label'
    @story.should_receive(:labels).and_return(old_labels)
    @story.should_receive(:update).with(:labels => ["other_label", "on_qa"]).and_return(false)
    lambda { GitPivotalTrackerIntegration::Util::Label.add(@story, 'on_qa') }.should raise_error SystemExit
  end

  it 'should abort when cannot remove labels from story' do
    old_labels = 'other_label,on_qa'
    @story.should_receive(:labels).and_return(old_labels)
    @story.should_receive(:update).with(:labels => ["other_label"]).and_return(false)
    lambda { GitPivotalTrackerIntegration::Util::Label.remove(@story, 'on_qa') }.should raise_error SystemExit
  end










  it 'should pretty print story labels' do
    @story.should_receive(:labels).and_return('label1,label2')
    GitPivotalTrackerIntegration::Util::Label.list @story
  end

  it 'should not pretty print description or notes if there are none (empty)' do
    story = double('story')
    story.should_receive(:name)
    story.should_receive(:description)
    PivotalTracker::Note.should_receive(:all).and_return([])

    GitPivotalTrackerIntegration::Util::Story.pretty_print story

    expect($stdout.string).to eq(
      "      Title: \n" +
      "\n")
  end

  it 'should not pretty print description or notes if there are none (nil)' do
    story = double('story')
    story.should_receive(:name)
    story.should_receive(:description).and_return('')
    PivotalTracker::Note.should_receive(:all).and_return([])

    GitPivotalTrackerIntegration::Util::Story.pretty_print story

    expect($stdout.string).to eq(
      "      Title: \n" +
      "\n")
  end

  it 'should assign owner to story and notify about success' do
    story = double('story')
    username = 'User Name'
    story.should_receive(:update).with({ :owned_by => username }).and_return(true)

    GitPivotalTrackerIntegration::Util::Story.assign story, username

    expect($stdout.string).to eq(
      "Story assigned to #{username}" +
      "\n")
  end

  it 'should change story state and notify about success' do
    story = double('story')
    state = 'finished'
    story.should_receive(:update).with({ :current_state => state }).and_return(true)

    GitPivotalTrackerIntegration::Util::Story.mark story, state

    expect($stdout.string).to eq(
      "Changed state to #{state}" +
      "\n")
  end

  it 'should select a story directly if the filter is a number' do
    @project.should_receive(:stories).and_return(@stories)
    @stories.should_receive(:find).with(12345678).and_return(@story)

    story = GitPivotalTrackerIntegration::Util::Story.select_story @project, '12345678'

    expect(story).to be(@story)
  end

  it 'should select a story if the result of the query is a single story' do
    @project.should_receive(:stories).and_return(@stories)
    @stories.should_receive(:all).with(
      :current_state => %w(rejected unstarted unscheduled),
      :story_type => 'release'
    ).and_return([@story])
    @story.should_receive(:owned_by)
    story = GitPivotalTrackerIntegration::Util::Story.select_story @project, 'release', 1

    expect(story).to be(@story)
  end

  it 'should prompt the user for a story if the result of the query is more than a single story' do
    @project.should_receive(:stories).and_return(@stories)
    @stories.should_receive(:all).with(
      :current_state => %w(rejected unstarted unscheduled),
      :story_type => 'feature'
    ).and_return([
      PivotalTracker::Story.new(:name => 'name-1'),
      PivotalTracker::Story.new(:name => 'name-2')
    ])
    @menu.should_receive(:prompt=)
    @menu.should_receive(:choice).with('name-1')
    @menu.should_receive(:choice).with('name-2')
    GitPivotalTrackerIntegration::Util::Story.should_receive(:choose) { |&arg| arg.call @menu }.and_return(@story)

    story = GitPivotalTrackerIntegration::Util::Story.select_story @project, 'feature'

    expect(story).to be(@story)
  end

  it 'should prompt the user with the story type if no filter is specified' do
    @project.should_receive(:stories).and_return(@stories)
    @stories.should_receive(:all).with(
      :current_state => %w(rejected unstarted unscheduled)
    ).and_return([
      PivotalTracker::Story.new(:story_type => 'chore', :name => 'name-1'),
      PivotalTracker::Story.new(:story_type => 'bug', :name => 'name-2')
    ])
    @menu.should_receive(:prompt=)
    @menu.should_receive(:choice).with('CHORE   name-1')
    @menu.should_receive(:choice).with('BUG     name-2')
    GitPivotalTrackerIntegration::Util::Story.should_receive(:choose) { |&arg| arg.call @menu }.and_return(@story)

    story = GitPivotalTrackerIntegration::Util::Story.select_story @project

    expect(story).to be(@story)
  end

end
