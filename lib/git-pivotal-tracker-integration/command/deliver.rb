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
require 'pivotal-tracker'

# The class that encapsulates starting a Pivotal Tracker Story
class GitPivotalTrackerIntegration::Command::Deliver < GitPivotalTrackerIntegration::Command::Base

  # Starts a Pivotal Tracker story by doing the following steps:
  # * Create a branch
  # * Add default commit hook
  # * Start the story on Pivotal Tracker
  #
  # @param [String, nil] filter a filter for selecting the story to start.  This
  #   filter can be either:
  #   * a story id
  #   * a story type (feature, bug, chore)
  #   * +nil+
  # @return [void]
  def run(filter)
    $LOG.debug("#{self.class} in project:#{@project.name} pwd:#{(GitPivotalTrackerIntegration::Util::Shell.exec 'pwd').chop} branch:#{GitPivotalTrackerIntegration::Util::Git.branch_name}")
    self.check_branch
    story = GitPivotalTrackerIntegration::Util::Story.select_release @project
    $LOG.debug("story:#{story.name}")
    sort_for_deliver story
    GitPivotalTrackerIntegration::Util::Story.pretty_print story

   current_branch = GitPivotalTrackerIntegration::Util::Git.branch_name

   puts "Merging from orgin develop..."
   GitPivotalTrackerIntegration::Util::Shell.exec "git pull"

   # checkout QA branch
   # Merge develop into QA
    GitPivotalTrackerIntegration::Util::Shell.exec "git checkout QA"
       GitPivotalTrackerIntegration::Util::Shell.exec "git pull"
    if (GitPivotalTrackerIntegration::Util::Shell.exec "git merge -s recursive --strategy-option theirs develop")
      puts "Merged 'develop' in to 'QA'"
    else
      abort "FAILED to merge 'develop' in to 'QA'"
    end

        puts "storyNAME:#{story.name}"

    # Update version and build numbers
    build_number = story.name.dup
    build_number[0] = ""
    puts "storyNAME:#{story.name}"
    puts "build_number:#{build_number}"
    project_directory = ((GitPivotalTrackerIntegration::Util::Shell.exec 'find . -name "*.xcodeproj" 2>/dev/null').split /\/(?=[^\/]*$)/)[0]
    working_directory = (GitPivotalTrackerIntegration::Util::Shell.exec "pwd").chop
    puts "working_directory:#{working_directory}*"
    
    # cd to the project_directory
    Dir.chdir(project_directory)

    # set build number and project number in project file
    GitPivotalTrackerIntegration::Util::Shell.exec "pwd"   
    puts GitPivotalTrackerIntegration::Util::Shell.exec "xcrun agvtool new-version -all #{build_number}", false
    puts GitPivotalTrackerIntegration::Util::Shell.exec "xcrun agvtool new-marketing-version SNAPSHOT"

    # cd back to the working_directory
    Dir.chdir(working_directory)

    # Create a new build commit, push to QA, checkout develop
    GitPivotalTrackerIntegration::Util::Git.create_commit( "Update build number to #{build_number} for delivery to QA", story)
    puts GitPivotalTrackerIntegration::Util::Shell.exec "git push" 
    puts GitPivotalTrackerIntegration::Util::Shell.exec "git checkout develop"

    i_stories = included_stories @project, story
    deliver_stories i_stories, story
  end

  def check_branch

      current_branch = GitPivotalTrackerIntegration::Util::Git.branch_name

      suggested_branch = "develop"

      if !suggested_branch.nil? && suggested_branch.length !=0 && current_branch != suggested_branch
          should_chage_branch = ask("Your currently checked out branch is '#{current_branch}'. You must be on the #{suggested_branch} branch to run this command.\n\n Do you want to checkout '#{suggested_branch}' before starting?(Y/n)")
          if should_chage_branch != "n"
              print "Checking out branch '#{suggested_branch}'...\n\n"
              GitPivotalTrackerIntegration::Util::Shell.exec "git checkout #{suggested_branch}"
              GitPivotalTrackerIntegration::Util::Shell.exec 'git pull'

          else
              abort "You must be on the #{suggested_branch} branch to run this command."
          end

      end

  end

  private

    CANDIDATE_STATES = %w(finished unstarted).freeze
    CANDIDATE_TYPES = %w(bug chore feature release)

def deliver_stories(stories, build_story)
  all_stories = stories.dup
  all_stories << build_story
  all_stories.each {|story|
    # puts "story class:#{story.class}"
    s_labels_string = story.labels
    s_labels = ""
    if (s_labels_string)
      s_labels = s_labels_string.split(",")
      s_labels << build_story.name
      s_labels_string = s_labels.uniq.join(",")
    else
      s_labels_string = build_story.name
    end
    
    # puts "labels:#{s_labels_string}"
    story.update(:labels => s_labels_string)
    if (story.story_type == "feature") || (story.story_type == "bug")
      story.update(:current_state => "delivered")
    elsif (story.story_type == "chore") 
      story.update(:current_state => "accepted")      
    end
  }
end

  def included_stories(project, build_story)

    criteria = {
      :current_state => CANDIDATE_STATES,
      :limit => 1000,
      :story_type => CANDIDATE_TYPES
    }
    

    candidates = project.stories.all criteria

    # only include stories that have been estimated
    estimated_candidates = Array.new
    val_is_valid = true
    puts "Included stories:\n"
    candidates.each {|val|
        val_is_valid = true
        if (val.id == build_story.id) 
          break
        end
        if (val.current_state != "finished")
          val_is_valid = false
        end
        if (val.story_type == "release")
          val_is_valid = false
        end
        if val_is_valid
          # puts "val_is_valid:#{val_is_valid}"
           estimated_candidates << val
           puts "#{val.id}"

        end 
    }
    candidates = estimated_candidates
  end


  def development_branch_name(story)
      prefix = "#{story.id}-"
      story_name = "#{story.name.gsub(/[^0-9a-z\\s]/i, '_')}"
      if(story_name.length > 30)
          suggested_suffix = story_name[0..27]
          suggested_suffix << "__"
      else
          suggested_suffix = story_name
      end
      branch_name = "#{prefix}" + ask("Enter branch name (#{story.id}-<#{suggested_suffix}>): ")
      puts
      if branch_name == "#{prefix}"
          branch_name << suggested_suffix
      end
      branch_name.gsub(/[^0-9a-z\\s\-]/i, '_')
  end

  def start_on_tracker(story)
    print 'Starting story on Pivotal Tracker... '
    story.update(
      :current_state => 'started',
      :owned_by => GitPivotalTrackerIntegration::Util::Git.get_config('user.name')
    )
    puts 'OK'
  end

  def sort_for_deliver(release_story)
    last_release = GitPivotalTrackerIntegration::Util::Story.last_release_story(@project, "b")
    stories = included_stories(@project, release_story)
    if last_release.nil?
      last_release = stories[0]
      stories.shift
    end
    stories << release_story
    previous_story = last_release.dup

    puts "Last release:#{previous_story.name}"
    stories.each {|story|
      story.move(:after, previous_story)
      previous_story = story.dup
    }
  end
end
