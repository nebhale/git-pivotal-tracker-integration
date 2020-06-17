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

require 'git-pivotal-tracker-integration/command/command'
require 'git-pivotal-tracker-integration/util/git'
require 'highline/import'
require 'pivotal-tracker'

# A class that exposes configuration that commands can use
class GitPivotalTrackerIntegration::Command::Configuration

  # Returns the user's Pivotal Tracker API token.  If this token has not been
  # configured, prompts the user for the value.  The value is checked for in
  # the _inherited_ Git configuration, but is stored in the _global_ Git
  # configuration so that it can be used across multiple repositories.
  #
  # @return [String] The user's Pivotal Tracker API token
  def api_token
    api_token = GitPivotalTrackerIntegration::Util::Git.get_config KEY_API_TOKEN, :inherited

    if api_token.empty?
      api_token = ask('Pivotal API Token (found at https://www.pivotaltracker.com/profile): ').strip
      GitPivotalTrackerIntegration::Util::Git.set_config KEY_API_TOKEN, api_token, :global
      puts
    end

    api_token
  end

  # Returns the Pivotal Tracker project id for this repository.  If this id
  # has not been configuration, prompts the user for the value.  The value is
  # checked for in the _inherited_ Git configuration, but is stored in the
  # _local_ Git configuration so that it is specific to this repository.
  #
  # @return [String] The repository's Pivotal Tracker project id
  def project_id
    project_id = GitPivotalTrackerIntegration::Util::Git.get_config KEY_PROJECT_ID, :inherited

    if project_id.empty?
      project_id = choose do |menu|
        menu.prompt = 'Choose project associated with this repository: '

        PivotalTracker::Project.all.sort_by { |project| project.name }.each do |project|
          menu.choice(project.name) { project.id }
        end
      end

      GitPivotalTrackerIntegration::Util::Git.set_config KEY_PROJECT_ID, project_id, :local
      puts
    end

    project_id
  end

  # Returns the Pivotal Tracker project for this repository.  If it is not
  # configured yet, prompts the user for the value.
  #
  # @return [PivotalTracker::Project] The repository's Pivotal Tracker project
  def project
    PivotalTracker::Project.find project_id
  end

  # Returns the Pivotal Tracker user id for this repository.  If this id
  # has not been configuration, prompts the user for the value.  The value is
  # checked for in the _inherited_ Git configuration, but is stored in the
  # _local_ Git configuration so that it is specific to this repository.
  #
  # @return [String] The repository's Pivotal Tracker user id
  def user
    user = GitPivotalTrackerIntegration::Util::Git.get_config KEY_USER, :inherited

    if user.empty?
      user = choose do |menu|
        menu.prompt = 'Choose your user name associated with this repository: '

        PivotalTracker::Project.all.map{ |p| p.memberships.all.map(&:name) }.flatten.uniq.each do |owner|
          menu.choice(owner) { owner }
        end
      end

      GitPivotalTrackerIntegration::Util::Git.set_config KEY_USER, user.inspect, :local
    end

    user
  end

  # Returns the story associated with the current development branch
  #
  # @return [PivotalTracker::Story] the story associated with the current development branch
  def story
    story_id = GitPivotalTrackerIntegration::Util::Git.get_config KEY_STORY_ID, :branch
    if story_id.empty?
      abort("You need to be on started story branch to do this!")
    else
      project.stories.find(story_id)
    end
  end

  # Stores the story associated with the current development branch
  #
  # @param [PivotalTracker::Story] story the story associated with the current development branch
  # @return [void]
  def story=(story)
    GitPivotalTrackerIntegration::Util::Git.set_config KEY_STORY_ID, story.id, :branch
  end

  private

  KEY_API_TOKEN = 'pivotal.api-token'.freeze

  KEY_USER = 'pivotal.user'.freeze

  KEY_PROJECT_ID = 'pivotal.project-id'.freeze

  KEY_STORY_ID = 'pivotal-story-id'.freeze

end
