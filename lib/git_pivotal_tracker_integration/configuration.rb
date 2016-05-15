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

require 'git_pivotal_tracker_integration/pivotal_tracker'
require 'rugged'

module GitPivotalTrackerIntegration

  class Configuration

    def api_token
      Rugged::Config.global['pivotal.api-token'] ||= choose_api_token
    end

    def pivotal_tracker
      @pivotal_tracker ||= PivotalTracker.new(api_token)
    end

    def project_id
      repository.config['pivotal.project-id'] ||= choose_project_id
    end

    def repository
      @repository ||= Rugged::Repository.discover
    end

    private

    def choose_api_token
      ask('Pivotal API Token (found at https://www.pivotaltracker.com/profile): ').strip
    end

    def choose_project_id
      choose do |menu|
        menu.prompt = 'Choose project associated with this repository: '

        pivotal_tracker.projects.sort_by { |project| project['name'] }.each do |project|
          menu.choice(project['name']) { project['id'] }
        end
      end
    end

  end

end
