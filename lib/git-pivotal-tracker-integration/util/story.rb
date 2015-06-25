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

module GitPivotalTrackerIntegration
  module Util

    # Utilities for dealing with +PivotalTracker::Story+s
    class Story

      CANDIDATE_STATES  = %w(rejected unstarted unscheduled).freeze
      LABEL_DESCRIPTION = 'Description'.freeze
      LABEL_TITLE       = 'Title'.freeze
      LABEL_WIDTH       = (LABEL_DESCRIPTION.length + 2).freeze
      CONTENT_WIDTH     = (HighLine.new.output_cols - LABEL_WIDTH).freeze

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

        story.comments.sort_by{ |comment| comment.updated_at }.each_with_index do |comment, index|
          print_label "Note #{index + 1}"
          print_value comment.text
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
        story = nil

        if filter =~ /[[:digit:]]/
          story = project.story filter.to_i
        else
          # story type from (feature, bug, chore)
          # state from (rejected unstarted unscheduled)
          # if story type is "feature", then retrieve only estimated ones.
          criteria = " state:unstarted,rejected,unscheduled"

          if %w(feature bug chore).include?(filter)
            criteria << " type:#{filter}"
            criteria << " -estimate:-1" if filter == "feature"
          else
            criteria << " type:feature,bug,chore"
          end

          candidates  = project.stories(filter: criteria, limit: limit)
          #limit is not working as expected. Need to find the reason. For now handle via ruby
          candidates  = candidates[0...5]
          story       = choose_story(candidates) unless candidates.empty?
        end

        story
      end

      def self.select_release(project, filter = 'b', limit = 10)
        if filter =~ /[[:digit:]]/
          story = project.story filter.to_i
          if story.story_type != "release"
            $LOG.fatal("Specified story##{filter} is not a valid release story")
            puts "Specified story##{filter} is not a valid release story"
            abort 'FAIL'
          end
        else
          story = find_release_story project, filter, limit
        end

        story
      end

      private

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

      def self.choose_story(candidates, type = nil)
        choose do |menu|
          puts "\nUnestimated features can not be started.\n\n" if type != "release"

          menu.prompt = 'Choose a story to start: '

          candidates.each do |story|
            name = type ? story.name : '%-7s %s' % [story.story_type.upcase, story.name]
            menu.choice(name) { story }
          end
          menu.choice('Quit') do
            say "Thank you for using v2gpti"
            exit 0
          end
        end
      end

      # story type  is release with story name starting with "v"/"b" or story labels includes story name.
      # state from (rejected unstarted unscheduled)
      # sort stories based on version (version number part of the story name) and pick the latest  one.
      def self.find_release_story(project, type, limit)
        release_type = (type == "b") ? "build" : "version"

        criteria =  "type:release"
        criteria << " state:unstarted,rejected"
        criteria << " name:/#{type}*/"    #story name starts with  b or v

        candidates = project.stories(filter: criteria, limit: limit)

        candidates = candidates.select do |story|
          labels = story.labels.map(&:name)
          !labels.include?(story.name)
        end

        unless candidates.empty?
          story = choose_story(candidates, "release")
        else
          puts "There are no available release stories."
          last_release = last_release_story(project, type)

          if last_release
            puts " The last #{release_type} release was #{last_release.name}."
            if release_type == "version"
              next_release_number = ask("To create a new #{release_type}, enter a name for the new release story:")
            else
              next_release_number = set_next_release_number(last_release, release_type)
            end
          else
            next_release_number = ask("To create a new #{release_type}, enter a name for the new release story:")
          end

          puts "New #{release_type} release number is: #{next_release_number}"
          story = self.create_new_release(project, next_release_number)
        end

        story
      end

      # sort stories based on version (version number part of the story name) and pick the latest  one.
      def self.last_release_story (project, type)

        candidates = project.stories filter: "type:release name:/#{type}*/"
        candidates = candidates.select do |story|
          labels = story.labels.map(&:name)
          labels.include?(story.name)
        end
        candidates.sort! { |x,y| Gem::Version.new(y.name[1 .. -1]) <=> Gem::Version.new(x.name[1 .. -1]) }

        candidates.first
      end

      def self.set_next_release_number(last_release, release_type)
        case release_type
        when "build"
          # just increment the last number
          last_release.name.next
        when "version"
          version_split           = last_release.name.split(/\./)
          last_incremented_number = version_split.last.next
          version_split.pop
          version_split.push(last_incremented_number)
          version_split.join(".")
        end
      end

      def self.create_new_release (project, next_release_number)
        project.create_story(:story_type => 'release', :current_state => 'unstarted', :name => next_release_number)
      end

    end
  end
end
