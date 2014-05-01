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
require 'git-pivotal-tracker-integration/util/story'
require 'pivotal-tracker'

describe GitPivotalTrackerIntegration::Util::Story do

  before do
    $stdout = StringIO.new
    $stderr = StringIO.new

    @project = double('project')
    @stories = double('stories')
    @story = double('story')
    @menu = double('menu')
  end

  it 'should pretty print story information' do
    story = double('story')
    story.should_receive(:name)
    story.should_receive(:description).and_return("description-1\ndescription-2")
    PivotalTracker::Note.should_receive(:all).and_return([
      PivotalTracker::Note.new(:noted_at => Date.new, :text => 'note-1')
    ])

    GitPivotalTrackerIntegration::Util::Story.pretty_print story

    expect($stdout.string).to eq(
      "      Title: \n" +
      "Description: description-1\n" +
      "             description-2\n" +
      "     Note 1: note-1\n" +
      "\n")
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
      :limit => 1,
      :story_type => 'release'
    ).and_return([@story])
    @story.stub(:story_type) {'release'}
    @story.stub(:name) {'story_name'}

    @menu.stub(:prompt=)
    @menu.stub(:choice)
    GitPivotalTrackerIntegration::Util::Story.should_receive(:choose) { |&arg| arg.call @menu }.and_return(@story)

    story = GitPivotalTrackerIntegration::Util::Story.select_story @project, 'release', 1

    expect(story).to be(@story)
  end

  it 'should prompt the user for a story if the result of the query is more than a single story' do
    @project.should_receive(:stories).and_return(@stories)
    @stories.should_receive(:all).with(
      :current_state => %w(rejected unstarted unscheduled),
      :limit => 5,
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
      :current_state => %w(rejected unstarted unscheduled),
      :limit => 5
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
