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

require "highline/import"
require "pivotal-tracker"
require "rugged"

class PivotalConfiguration

  @@KEY_API_TOKEN = "pivotal.api-token"

  @@KEY_PROJECT_ID = "pivotal.project-id"

  def initialize(repository)
    @global_config = Rugged::Config.global
    @local_config = repository.config
  end

  def api_token
    if !@global_config[@@KEY_API_TOKEN]
      @global_config[@@KEY_API_TOKEN] = ask("Pivotal API Key (found at https://www.pivotaltracker.com/profile): ")
    end

    @global_config[@@KEY_API_TOKEN]
  end

  def project_id
    if !@local_config[@@KEY_PROJECT_ID]
      @local_config[@@KEY_PROJECT_ID] = choose do |menu|
        menu.prompt = "Project associated with this repository: "

        PivotalTracker::Project.all.sort_by { |project| project.name }.each do |project|
          menu.choice("#{project.name} (#{project.id})") { project.id }
        end
      end
    end

    @local_config[@@KEY_PROJECT_ID]
  end

end
