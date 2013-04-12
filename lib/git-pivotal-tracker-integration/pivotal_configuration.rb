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

class PivotalConfiguration

  def self.api_token
    api_token = `git config #{@@KEY_API_TOKEN}`

    if api_token.nil? || api_token.empty?
      api_token = ask("Pivotal API Token (found at https://www.pivotaltracker.com/profile): ")
      `git config --global #{@@KEY_API_TOKEN} #{api_token}`
      puts
    end

    api_token.strip
  end

  def self.merge_remote
    `git config branch.#{merge_target}.#{@@KEY_REMOTE}`.strip
  end

  def self.merge_target
    `git config branch.#{branch_name}.#{@@KEY_MERGE_TARGET}`.strip
  end

  def self.merge_target=(value)
    `git config --local branch.#{branch_name}.#{@@KEY_MERGE_TARGET} #{value}`
  end

  def self.story_id
    `git config branch.#{branch_name}.#{@@KEY_STORY_ID}`.strip
  end

  def self.story_id=(value)
    `git config --local branch.#{branch_name}.#{@@KEY_STORY_ID} #{value}`
  end

  def self.project_id
    project_id = `git config #{@@KEY_PROJECT_ID}`

    if project_id.nil? || project_id.empty?
      project_id = choose do |menu|
        menu.prompt = "Choose project associated with this repository: "

        PivotalTracker::Project.all.sort_by { |project| project.name }.each do |project|
          menu.choice(project.name) { project.id }
        end
      end

      `git config --local #{@@KEY_PROJECT_ID} #{project_id}`
      puts
    end

    project_id.strip
  end

  private

  @@KEY_API_TOKEN = "pivotal.api-token"

  @@KEY_MERGE_TARGET = "pivotal-merge-target"

  @@KEY_PROJECT_ID = "pivotal.project-id"

  @@KEY_REMOTE = "remote"

  @@KEY_STORY_ID = "pivotal-story-id"

  def self.branch_name
    `git branch`.scan(/\* (.*)/)[0][0]
  end

end
