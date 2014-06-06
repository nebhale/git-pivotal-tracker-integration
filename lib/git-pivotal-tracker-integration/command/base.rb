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
require 'git-pivotal-tracker-integration/command/configuration'
require 'git-pivotal-tracker-integration/util/git'
require 'pivotal-tracker'
require 'parseconfig'
require 'logger'

# An abstract base class for all commands
# @abstract Subclass and override {#run} to implement command functionality
class GitPivotalTrackerIntegration::Command::Base

  # Common initialization functionality for all command classes.  This
  # enforces that:
  # * the command is being run within a valid Git repository
  # * the user has specified their Pivotal Tracker API token
  # * all communication with Pivotal Tracker will be protected with SSL
  # * the user has configured the project id for this repository
  def initialize
    self.start_logging
    self.check_version
    @repository_root = GitPivotalTrackerIntegration::Util::Git.repository_root
    @configuration = GitPivotalTrackerIntegration::Command::Configuration.new
    @toggle = Toggl.new

    PivotalTracker::Client.token = @configuration.api_token
    PivotalTracker::Client.use_ssl = true

    @project = PivotalTracker::Project.find @configuration.project_id
  end

  def start_logging
    $LOG = Logger.new("#{Dir.home}/.v2gpti_local.log", 'weekly') 
  end

  def check_version
    gem_latest_version = (GitPivotalTrackerIntegration::Util::Shell.exec "gem list v2gpti --remote")[/\(.*?\)/].delete "()"
    gem_installed_version = Gem.loaded_specs["v2gpti"].version.version
    if (gem_installed_version == gem_latest_version)
        $LOG.info("v2gpti verison #{gem_installed_version} is up to date.")
    else
        $LOG.fatal("Out of date")
        abort "\n\nYou are using v2gpti version #{gem_installed_version}, but the current version is #{gem_latest_version}.\nPlease update your gem with the following command.\n\n    sudo gem update v2gpti\n\n"  
        
    end
  end

  # The main entry point to the command's execution
  # @abstract Override this method to implement command functionality
  def run
    raise NotImplementedError
  end

end
