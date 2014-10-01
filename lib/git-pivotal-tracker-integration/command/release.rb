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

require 'git-pivotal-tracker-integration/command/base'
require 'git-pivotal-tracker-integration/command/command'
require 'git-pivotal-tracker-integration/util/git'
require 'git-pivotal-tracker-integration/util/story'
require 'git-pivotal-tracker-integration/version-update/gradle'

# The class that encapsulates releasing a Pivotal Tracker Story
class GitPivotalTrackerIntegration::Command::Release < GitPivotalTrackerIntegration::Command::Base

  # Releases a Pivotal Tracker story by doing the following steps:
  # * Update the version to the release version
  # * Create a tag for the release version
  # * Update the version to the new development version
  # * Push tag and changes to remote
  #
  # @param [String, nil] filter a filter for selecting the release to start.  This
  #   filter can be either:
  #   * a story id
  #   * +nil+
  # @return [void]
  def run(filter)
    $LOG.debug("#{self.class} in project:#{@project.name} pwd:#{pwd} branch:#{GitPivotalTrackerIntegration::Util::Git.branch_name}")
    story = GitPivotalTrackerIntegration::Util::Story.select_release(@project, filter.nil? ? 'v' : filter)
    place_version_release story
    pull_out_rejected_stories story
    GitPivotalTrackerIntegration::Util::Story.pretty_print story
    $LOG.debug("story:#{story.name}")

    current_branch = GitPivotalTrackerIntegration::Util::Git.branch_name

    # checkout QA branch
    # Update QA from origin
    puts GitPivotalTrackerIntegration::Util::Shell.exec "git checkout QA"
    puts GitPivotalTrackerIntegration::Util::Shell.exec "git fetch"
    GitPivotalTrackerIntegration::Util::Shell.exec "git merge -s recursive --strategy-option theirs origin QA"

    # checkout master branch
    # Merge QA into master
    puts GitPivotalTrackerIntegration::Util::Shell.exec "git checkout master"
    puts GitPivotalTrackerIntegration::Util::Shell.exec "git pull"
    if (GitPivotalTrackerIntegration::Util::Shell.exec "git merge -s recursive --strategy-option theirs QA")
      puts "Merged 'QA' in to 'master'"
    else
      abort "FAILED to merge 'QA' in to 'master'"
    end

    # Update version and build numbers
    version_number    = story.name.dup
    version_number[0] = ""
    working_directory = pwd

    puts "storyNAME:#{story.name}"
    puts "version_number:#{version_number}"
    puts "working_directory:#{working_directory}*"

    if (OS.mac? && ["y","ios"].include?(@platform.downcase))
      project_directory = ((GitPivotalTrackerIntegration::Util::Shell.exec 'find . -name "*.xcodeproj" 2>/dev/null').split /\/(?=[^\/]*$)/)[0]

      # cd to the project_directory
      Dir.chdir(project_directory)

      # set project number in project file
      pwd
      puts GitPivotalTrackerIntegration::Util::Shell.exec "xcrun agvtool new-marketing-version #{version_number}"

      # cd back to the working_directory
      Dir.chdir(working_directory)
    end
    
    # Change spec version
    change_spec_version(version_number) if has_spec_path?

    # Create a new build commit, push to QA
    puts GitPivotalTrackerIntegration::Util::Git.create_commit( "Update version number to #{version_number} for delivery to QA", story)
    puts GitPivotalTrackerIntegration::Util::Shell.exec "git push"
    
    # Create release tag
    create_release_tag(version_number) if has_spec_path?

    #Created tag should be pushed to private Podspec repo
    if has_spec_path? && @platform == "ios"
      puts GitPivotalTrackerIntegration::Util::Shell.exec "git checkout #{version_number}"
      puts GitPivotalTrackerIntegration::Util::Shell.exec "pod repo push V2PodSpecs #{@configuration.pconfig["spec"]["spec-path"]}"
      puts GitPivotalTrackerIntegration::Util::Shell.exec "git checkout develop"
    end
    
    #checkout develop branch
    puts GitPivotalTrackerIntegration::Util::Shell.exec "git checkout #{current_branch}"

    s_labels_string = story.labels
    s_labels = ""
    if (s_labels_string)
      s_labels = s_labels_string.split(",")
      s_labels << story.name
      s_labels_string = s_labels.uniq.join(",")
    else
      s_labels_string = story.name
    end

    puts "labels:#{s_labels_string}"
    story.update(:labels => s_labels_string)

    i_stories = included_stories @project, story
    add_version_tag_to_stories i_stories, story

  end
  
  private

  CANDIDATE_STATES = %w(delivered unstarted).freeze
  CANDIDATE_TYPES = %w(bug chore feature release)

  def add_version_tag_to_stories(stories, release_story)
    all_stories = stories.dup
    all_stories << release_story
    puts "Included stories:\n"
    all_stories.each {|story|
      s_labels_string = story.labels
      s_labels = ""
      if (s_labels_string)
        s_labels = s_labels_string.split(",")
        s_labels << release_story.name
        s_labels_string = s_labels.uniq.join(",")
      else
        s_labels_string = release_story.name
      end

      unless story.labels.nil?
        if story.labels.scan(/b\d{1}/).size > story.labels.scan(/v\d{1}/).size
          story.update(:labels => s_labels_string)
          puts story.id
        end
      end 
    }
  end

  def included_stories(project, release_story)

    criteria = {
      :current_state => CANDIDATE_STATES,
      :limit => 1000,
      :story_type => CANDIDATE_TYPES
    }


    candidates = project.stories.all criteria

    estimated_candidates = Array.new
    val_is_valid = true
    
    candidates.each do |val|
      val_is_valid = true
      if (val.id == release_story.id)
        next
      end
      if (val.current_state != "delivered")
        val_is_valid = false
      end
      if (val.story_type == "release")
        val_is_valid = false
      end
      if val_is_valid
         estimated_candidates << val
      end
    end
    candidates = estimated_candidates
  end
  
  def place_version_release(release_story)
	not_accepted_releases = nil
	not_accepted_releases_ids = nil
	not_accepted_releases = @project.stories.all(:current_state => 'unstarted', :story_type => 'release')
	not_accepted_releases_ids = Array.new
	not_accepted_releases.collect{|not_accepted_release| not_accepted_releases_ids.push not_accepted_release.id.to_i }
	unless (not_accepted_releases_ids.include?(release_story.id))
		not_accepted_releases << release_story
		not_accepted_releases_ids.clear
		not_accepted_releases.collect{|not_accepted_release| not_accepted_releases_ids.push not_accepted_release.id.to_i }
	end
    specified_pt_story = @project.stories.all(:current_state => ['unstarted', 'started', 'finished', 'delivered', 'rejected']).first
    last_accepted_release_story=@project.stories.all(:current_state => 'accepted', :story_type => 'release').last
    if not_accepted_releases.size > 1
		release_story.move(:after, not_accepted_releases[not_accepted_releases.size - 2])
    elsif !specified_pt_story.nil?
		release_story.move(:before, specified_pt_story)
    end
  end
  
  def pull_out_rejected_stories(release_story)
      rejected_stories=@project.stories.all(:current_state => ['rejected'], :story_type => ['bug', 'chore', 'feature'])
      rejected_stories.each{|rejected_story|
          rejected_story.move(:after, release_story)
      }	
  end
  
  def has_spec_path?
      config_file_path = "#{GitPivotalTrackerIntegration::Util::Git.repository_root}/.v2gpti/config"
      config_file_text = File.read(config_file_path)
      spec_pattern_check = /spec-path(.*)=/.match("#{config_file_text}")
      if spec_pattern_check.nil?
          return false
          else
          spec_file_path = @configuration.pconfig["spec"]["spec-path"]
          if spec_file_path.nil?
              return false
              else
              return true
          end
      end
  end
  
  def change_spec_version(version_number)
      spec_file_path = "#{GitPivotalTrackerIntegration::Util::Git.repository_root}/#{@configuration.pconfig["spec"]["spec-path"]}"
      spec_file_text = File.read(spec_file_path)
      File.open(spec_file_path, "w") {|file| file.puts spec_file_text.gsub(/version(.*)=(.*)['|"]/, "version     = '#{version_number}'")}
  end
                                                                           
  def create_release_tag(version_number)
      GitPivotalTrackerIntegration::Util::Shell.exec "git tag -a #{version_number} -m \"release #{version_number}\""
      puts GitPivotalTrackerIntegration::Util::Shell.exec "git push origin #{version_number}"
  end

end
