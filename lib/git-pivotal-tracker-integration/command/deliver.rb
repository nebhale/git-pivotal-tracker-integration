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

module GitPivotalTrackerIntegration
  module Command
    # The class that encapsulates starting a Pivotal Tracker Story
    class Deliver < Base

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
        $LOG.debug("#{self.class} in project:#{@project.name} pwd:#{pwd} branch:#{Util::Git.branch_name}")
        self.check_branch
        story = Util::Story.select_release @project
        $LOG.debug("Release Story:#{story.name}")
        sort_for_deliver story
        Util::Story.pretty_print story

        current_branch = Util::Git.branch_name

        puts "Merging from orgin develop..."
        Util::Shell.exec "git pull"

        # checkout QA branch
        # Merge develop into QA
        Util::Shell.exec "git checkout QA"
        Util::Shell.exec "git reset --hard origin/QA"
        Util::Shell.exec "git pull"
        if (Util::Shell.exec "git merge -s recursive --strategy-option theirs develop")
          puts "Merged 'develop' in to 'QA'"
        else
          abort "FAILED to merge 'develop' in to 'QA'"
        end

        # retrieve build number from story name
        build_number      = story.name.slice(1..-1)
        working_directory = pwd

        puts "Story Name:         #{story.name}"
        puts "Build Number:       #{build_number}"
        puts "Working Directory:  #{working_directory}*"
        puts ""

        if (OS.mac? && @platform.downcase == "ios")
          project_directory = ((Util::Shell.exec 'find . -name "*.xcodeproj" 2>/dev/null').split /\/(?=[^\/]*$)/)[0]

          # cd to the project_directory
          Dir.chdir(project_directory)

          # set build number and project number in project file
          pwd
          puts Util::Shell.exec "xcrun agvtool new-version -all #{build_number}", false
          puts Util::Shell.exec "xcrun agvtool new-marketing-version SNAPSHOT"

          # cd back to the working_directory
          Dir.chdir(working_directory)
        elsif @platform == 'android'
          updater = VersionUpdate::Gradle.new(@repository_root)
          updater.update_qa_version(build_number)
        end

        # Create a new build commit, push to QA, checkout develop
        Util::Git.create_commit( "Update build number to #{build_number} for delivery to QA", story)
        puts Util::Shell.exec "git push"
        puts Util::Shell.exec "git checkout develop"

        i_stories = included_stories @project, story
        deliver_stories i_stories, story
      end

      def check_branch

        current_branch    = Util::Git.branch_name
        suggested_branch  = "develop"

        if !suggested_branch.nil? && suggested_branch.length !=0 && current_branch != suggested_branch
          should_chage_branch = ask("Your currently checked out branch is '#{current_branch}'. You must be on the #{suggested_branch} branch to run this command.\n\n Do you want to checkout '#{suggested_branch}' before starting?(Y/n)")
          if should_chage_branch != "n"
            print "Checking out branch '#{suggested_branch}'...\n\n"
            Util::Shell.exec "git checkout #{suggested_branch}"
            Util::Shell.exec 'git pull'
          else
              abort "You must be on the #{suggested_branch} branch to run this command."
          end
        end
      end

      private

      def deliver_stories(stories, build_story)
        all_stories = stories.dup
        all_stories << build_story

        all_stories.each do |story|
          labels = story.labels.map(&:name)
          labels << build_story.name
          labels.uniq!

          story.add_labels(*labels)

          case story.story_type
          when 'feature', 'bug'
            story.current_state = 'delivered'
          when 'chore'
            story.current_state = 'accepted'
          end
          story.save
        end
      end

      def included_stories(project, build_story)

        stories = project.stories(filter: "current_state:finished  type:bug,chore,feature -id:#{build_story.id}", limit: 1000)

        # capture story details in a file as well as to stdout
        FileUtils.mkdir_p 'release_notes'
        notes_file = File.join("release_notes", "#{project.name}-#{build_story.name}.txt")

        File.open(notes_file, 'w') do |file|
          puts "Included Stories"
          file.puts "Included Stories"

          stories.each do |story|
            file.puts "#{story.id} - #{story.name}"
            puts "#{story.id} - #{story.name}"
          end
        end

        stories
      end

      def sort_for_deliver(release_story)
        last_release  = Util::Story.last_release_story(@project, "b")
        stories       = included_stories(@project, release_story)
        last_release  = stories.shift if last_release.nil?

        abort "\nThere are no last release stories or finished stories to deliver" if last_release.nil?
        stories << release_story
        previous_story = last_release.dup

        puts "Last release:#{previous_story.name}"
        last_accepted_release_story = @project.stories(filter: "current_state:accepted type:release").last
        not_accepted_releases       = @project.stories(filter: "current_state:unstarted type:release")
        stories.reverse!

        stories.each do |story|
          if not_accepted_releases.size == 1 && !last_accepted_release_story.nil?
            story.after_id = last_accepted_release_story.id
          elsif previous_story.current_state == 'accepted'
            story.after_id = not_accepted_releases[not_accepted_releases.size - 2].id
          else
            story.after_id = previous_story.id
          end
          story.save
        end
      end

    end
  end
end
