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
  def self.select_story(project, filter = nil, limit = 12)
    if filter =~ /[[:digit:]]/
      story = project.stories.find filter.to_i
    else
      story = find_story project, filter, limit
    end

    story
  end

  def self.select_release(project, filter = 'b', limit = 10)
    if filter =~ /[[:digit:]]/
      story = project.stories.find filter.to_i
      if story.(story_type != "release")
        story = nil
        $LOG.fatal("Specified story##{filter} is not a valid release story")
        puts "Specified story##{filter} is not a valid release story"
        abort 'FAIL'
      end
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
    if (type == "b" || type == "v")
      release_type = type
      type = "release"      
    end
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
    val_is_valid = true

    candidates.each {|val|
        val_is_valid = true
        if (val.story_type == "feature" ) 
          # puts "#{val.story_type} #{val.name}.estimate:#{val.estimate} "
          if (val.estimate < 0)
            # puts "#{val.estimate} < 0" 
            val_is_valid = false 
          end
        elsif (val.story_type == "release")
          label_string = val.labels
          if label_string.nil?
            label_string = "";            
          end
          if (val.name[0] != release_type) || (label_string.include? val.name)
            val_is_valid = false
          end
        end

        if val_is_valid
          # puts "val_is_valid:#{val_is_valid}"
           estimated_candidates << val
        end 
    }
    candidates = estimated_candidates

    if candidates.length != 0
      story = choose do |menu|
        if type != "release"
          puts "\nUnestimated features can not be started.\n\n"
        end

        menu.prompt = 'Choose a story to start: '

        candidates.each do |story|
          name = type ? story.name : '%-7s %s' % [story.story_type.upcase, story.name]
          menu.choice(name) { story }
        end
      end

      puts
    else
      if type == "release"
        last_release = last_release_story(project, release_type)
        last_release_number = last_release.name if !last_release.nil?
        last_release_type_string = (release_type == "b")?"build":"version"
        puts "There are no available release stories."
        puts " The last #{last_release_type_string} release was #{last_release_number}." if !last_release.nil?
        next_release_number = ask("To create a new #{last_release_type_string}, enter a name for the new release story:")
        story = self.create_new_release(project, next_release_number)
      else
        puts
      end
    end

    

    story
  end

  def self.last_release_story (project, release_type)
    criteria = {
        :story_type => "release"
    }

    candidates = project.stories.all criteria
    candidates = candidates.select {|x| (x.name[0]==release_type) && !(x.labels.nil? || (!x.labels.include?x.name))}

    candidates[-1]
  end

  def self.create_new_release (project, next_release_number)
    new_story = PivotalTracker::Story.new
    new_story.project_id = project.id
    new_story.story_type = "release"
    new_story.current_state = "unstarted"
    new_story.name = next_release_number

    uploaded_story = new_story.create
  end
end
