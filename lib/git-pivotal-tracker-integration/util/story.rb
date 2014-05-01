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

require 'git-pivotal-tracker-integration/util/util'
require 'highline/import'
require 'pivotal-tracker'

# Utilities for dealing with +PivotalTracker::Story+s
class GitPivotalTrackerIntegration::Util::Story

  # Print a human readable version of a story.  This pretty prints the title,
  # description, and notes for the story.
  #
  # @param [PivotalTracker::Story] story the story to pretty print
  # @return [void]
  def self.pretty_print(story)
    print_label LABEL_TITLE
    print_value story.name

    description = story.description
    if !description.nil? && !description.empty?
      print_label 'Description'
      print_value description
    end

    PivotalTracker::Note.all(story).sort_by { |note| note.noted_at }.each_with_index do |note, index|
      print_label "Note #{index + 1}"
      print_value note.text
    end

    puts
  end

  # Selects a Pivotal Tracker story by doing the following steps:
  #
  # @param [PivotalTracker::Project] project the project to select stories from
  # @param [String, nil] filter a filter for selecting the story to start.  This
  #   filter can be either:
  #   * a story id: selects the story represented by the id
  #   * a story type (feature, bug, chore): offers the user a selection of stories of the given type
  #   * +nil+: offers the user a selection of stories of all types
  # @param [Fixnum] limit The number maximum number of stories the user can choose from
  # @return [PivotalTracker::Story] The Pivotal Tracker story selected by the user
  def self.select_story(project, filter = nil, limit = 5)
    if filter =~ /[[:digit:]]/
      story = project.stories.find filter.to_i
    else
      story = find_story project, filter, limit
    end

    story
  end

  private

  CANDIDATE_STATES = %w(rejected unstarted unscheduled).freeze

  LABEL_DESCRIPTION = 'Description'.freeze

  LABEL_TITLE = 'Title'.freeze

  LABEL_WIDTH = (LABEL_DESCRIPTION.length + 2).freeze

  CONTENT_WIDTH = (HighLine.new.output_cols - LABEL_WIDTH).freeze

  def self.print_label(label)
    print "%#{LABEL_WIDTH}s" % ["#{label}: "]
  end

  def self.print_value(value)
    if value.nil? || value.empty?
      puts ''
    else
      value.scan(/\S.{0,#{CONTENT_WIDTH - 2}}\S(?=\s|$)|\S+/).each_with_index do |line, index|
        if index == 0
          puts line
        else
          puts "%#{LABEL_WIDTH}s%s" % ['', line]
        end
      end
    end
  end

  def self.find_story(project, type, limit)
    criteria = {
      :current_state => CANDIDATE_STATES,
      :limit => limit
    }
    if type
      criteria[:story_type] = type
    end

    candidates = project.stories.all criteria

    # only include stories that have been estimated
    estimated_candidates = Array.new
    candidates.each {|val|
        #puts "story_type:#{val.story_type} estimate:#{val.estimate}"
        if !(val.story_type == "feature" && val.estimate < 0)
            estimated_candidates << val
        end
    }
    candidates = estimated_candidates


      story = choose do |menu|
        puts "\nUnestimated features can not be started.\n\n"
        menu.prompt = 'Choose a story to start: '

        candidates.each do |story|
          name = type ? story.name : '%-7s %s' % [story.story_type.upcase, story.name]
          menu.choice(name) { story }
        end
      end

      puts
    

    story
  end

end
