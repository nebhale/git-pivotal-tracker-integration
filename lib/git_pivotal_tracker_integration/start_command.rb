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
      puts story args.first
    end

    def story(filter)
      if filter.nil?
        chose_story @pivotal_tracker.stories(@project_id)
      elsif filter.integer?
        @pivotal_tracker.story @project_id, filter.to_i
      else
        chose_story @pivotal_tracker.stories(@project_id, filter)
      end
    end

    private

    def chose_story(stories)
      choose do |menu|
        menu.prompt = 'Choose story to start: '

        stories.each do |story|
          menu.choice('%-7s %s' % [story['story_type'].upcase, story['name']]) { story }
        end
      end
    end

  end

end

class String

  def integer?
    to_i.to_s == self
  end

end
