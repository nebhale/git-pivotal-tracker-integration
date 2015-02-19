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
require 'git-pivotal-tracker-integration/util/togglV8'
require 'time'

# A class that exposes configuration that commands can use
class GitPivotalTrackerIntegration::Command::Configuration

  # Returns the user's Pivotal Tracker API token.  If this token has not been
  # configured, prompts the user for the value.  The value is checked for in
  # the _inherited_ Git configuration, but is stored in the _global_ Git
  # configuration so that it can be used across multiple repositories.
  #
  # @return [String] The user's Pivotal Tracker API token

  def initialize
    check_for_config_file
    check_for_config_contents
  end
  def api_token
    api_token = GitPivotalTrackerIntegration::Util::Git.get_config KEY_API_TOKEN, :inherited
    if api_token.empty?
      api_token = ask('Pivotal API Token (found at https://www.pivotaltracker.com/profile): ').strip
      GitPivotalTrackerIntegration::Util::Git.set_config KEY_API_TOKEN, api_token, :global
      puts
    end  
    self.check_config_project_id

    api_token
  end

  def toggl_project_id
    toggle_config = self.pconfig["toggl"]
    if toggle_config.nil?
      abort "toggle project id not set"
    else
      toggle_config["project-id"]
    end
  end

  def check_config_project_id
    GitPivotalTrackerIntegration::Util::Git.set_config("pivotal.project-id", self.pconfig["pivotal-tracker"]["project-id"])
    nil
  end

  def pconfig
    pc = nil
    config_filename = "#{GitPivotalTrackerIntegration::Util::Git.repository_root}/.v2gpti/config"
    if File.file?(config_filename)
      pc = ParseConfig.new(config_filename)
    end
    pc
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
  
  def platform_name
    platform_name = self.pconfig["platform"]["platform-name"].downcase

    if platform_name.empty?
		platforms = ["ios", "non-ios"]
		platform_name = choose do |menu|
			menu.prompt = 'Please choose your project platform:'
			menu.choices(*platforms) do |chosen|
				chosen
			end
		end
		config_filename = "#{GitPivotalTrackerIntegration::Util::Git.repository_root}/.v2gpti/config"
        pc_text = File.read(config_filename)
        File.open(config_filename, "w") {|file| file.puts pc_text.gsub(/platform-name[\s+]?=/, "platform-name = #{platform_name}")}
    end
    puts "Your project platform is:#{platform_name}"
    platform_name
  end

  # Returns the story associated with the current development branch
  #
  # @param [PivotalTracker::Project] project the project the story belongs to
  # @return [PivotalTracker::Story] the story associated with the current development branch
  def story(project)
    $LOG.debug("#{self.class}:#{__method__}")
    story_id = GitPivotalTrackerIntegration::Util::Git.get_config KEY_STORY_ID, :branch
    $LOG.debug("story_id:#{story_id}")
    project.stories.find story_id.to_i
  end

  # Stores the story associated with the current development branch
  #
  # @param [PivotalTracker::Story] story the story associated with the current development branch
  # @return [void]
  def story=(story)
    GitPivotalTrackerIntegration::Util::Git.set_config KEY_STORY_ID, story.id, :branch
  end

  private

  def check_for_config_file
    rep_path = GitPivotalTrackerIntegration::Util::Git.repository_root
    FileUtils.mkdir_p(rep_path + '/.v2gpti') unless Dir.exists?( rep_path + '/.v2gpti/')
    unless File.exists?(rep_path + '/.v2gpti/config')
      FileUtils.cp(File.expand_path(File.dirname(__FILE__) + '/../../..') + '/config_template', rep_path + '/.v2gpti/config')
      @new_config = true
    end
  end

  def check_for_config_contents
    config_filename = "#{GitPivotalTrackerIntegration::Util::Git.repository_root}/.v2gpti/config"
    pc = ParseConfig.new(config_filename) if File.file?(config_filename)

    config_content = {}
    pc.params.each do |key,value|
      if value.is_a?(Hash)
        value.each do |child_key, child_value|
          populate_and_save(child_key,child_value,config_content,key)
        end
      else
        populate_and_save(key,value,config_content)
      end
    end

    pc.params = config_content

    File.open(config_filename, 'w') do |file|
      pc.write(file, false)
    end

    puts "For any modification, please update the details in #{config_filename}" if @new_config
  end

  def populate_and_save(key,value,hash, parent=nil)
    mandatory_details = %w(pivotal-tracker-project-id platform-platform-name)
    if value.empty?
      mandatory_field = mandatory_details.include?([parent,key].compact.join('-'))
      val =
          if mandatory_field || @new_config
            if key.include?('project-id')
              ask("Please provide #{parent.nil? ? '' :parent.capitalize} #{key.capitalize} value: ", lambda{|ip| mandatory_field ? Integer(ip) : ip =~ /^$/ ? '' : Integer(ip) }) do |q|
                q.responses[:invalid_type] = "Please provide valid project-id#{mandatory_field ? '' : '(or blank line to skip)'}"
              end
            elsif key.include?('platform-name')
              say("Please provide #{parent.nil? ? '' :parent.capitalize} #{key.capitalize} value: \n")
              choose do |menu|
                menu.prompt = 'Enter any of the above choices: '
                menu.choices('ios','non-ios')
              end
            else
              ask("Please provide #{parent.nil? ? '' :parent.capitalize} #{key.capitalize} value: ")
            end
          end
      value = val
    end

    if parent.nil?
      hash[key.to_s] = value
    else
      if hash.has_key?(parent.to_s) && hash[parent.to_s].has_key?(key.to_s)
        hash[parent.to_s][key.to_sym] = value.to_s
      else
        hash[parent.to_s] = Hash.new if !hash.has_key?(parent.to_s)
        hash[parent.to_s].store(key.to_s,value.to_s)
      end
    end
    hash
  end

  KEY_API_TOKEN = 'pivotal.api-token'.freeze

  KEY_PROJECT_ID = 'pivotal.project-id'.freeze
  
  KEY_PLATFORM_NAME = 'platform.platform-name'.freeze

  KEY_STORY_ID = 'pivotal-story-id'.freeze

end
