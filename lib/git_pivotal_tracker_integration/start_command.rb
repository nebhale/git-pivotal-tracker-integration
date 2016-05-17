# Git Pivotal Tracker Integration
# Copyright 2013-2016 the original author or authors.
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

require 'git_pivotal_tracker_integration/configuration'
require 'highline/import'

module GitPivotalTrackerIntegration

  class StartCommand

    def initialize
      configuration    = Configuration.new
      @pivotal_tracker = configuration.pivotal_tracker
      @project_id      = configuration.project_id
    end

    def run(args, _)
      story  = story args.first
      branch = branch story

      # create branch
      # add hook
      # start tracker
    end

    LABEL_WIDTH = 13.freeze

    VALUE_WIDTH = (HighLine.new.output_cols - LABEL_WIDTH).freeze

    private_constant :LABEL_WIDTH, :VALUE_WIDTH

    private

    def branch(story)
      choose_branch story
    end

    def choose_branch(story)
      puts
      puts [format_value('Title: ', story['name']),
            format_value('Description: ', story['description'])].join("\n")

      puts
      "#{story['id']}-#{ask("Enter branch name (#{story['id']}-<branch-name>): ")}"
    end

    def choose_story(stories)
      puts
      choose do |menu|
        menu.prompt = 'Choose story to start: '
        stories.each { |story| menu.choice(format_choice(story)) { story } }
      end
    end

    def format_choice(story)
      '%-7s %s' % [story['story_type'].upcase, story['name']]
    end

    def format_value(label, value)
      return "%#{LABEL_WIDTH}s\n" % [label] if value.nil?

      value.scan(/\S.{0,#{VALUE_WIDTH - 2}}\S(?=\s|$)|\S+/).map.with_index do |line, index|
        if index == 0
          "%#{LABEL_WIDTH}s%s" % [label, line]
        else
          "%#{LABEL_WIDTH}s%s" % ['', line]
        end
      end.join("\n")
    end

    def story(filter)
      if filter.nil?
        choose_story @pivotal_tracker.stories(@project_id)
      elsif filter.integer?
        @pivotal_tracker.story @project_id, filter.to_i
      else
        choose_story @pivotal_tracker.stories(@project_id, filter)
      end
    end

  end

end

class String

  def integer?
    to_i.to_s == self
  end

end
