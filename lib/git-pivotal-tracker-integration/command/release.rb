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

    # The class that encapsulates releasing a Pivotal Tracker Story
    class Release < Base

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

        $LOG.debug("#{self.class} in project:#{@project.name} pwd:#{pwd} branch:#{Util::Git.branch_name}")
        story = Util::Story.select_release(@project, filter.nil? ? 'v' : filter)
        place_version_release story
        pull_out_rejected_stories story
        Util::Story.pretty_print story
        $LOG.debug("story:#{story.name}")

        current_branch = Util::Git.branch_name

        # checkout QA branch
        # Update QA from origin
        puts Util::Shell.exec "git checkout QA"
        puts Util::Shell.exec "git fetch"
        Util::Shell.exec "git merge -s recursive --strategy-option theirs origin QA"

        # checkout master branch
        # Merge QA into master
        puts Util::Shell.exec "git checkout master"
        puts Util::Shell.exec "git pull"
        if (Util::Shell.exec "git merge -s recursive --strategy-option theirs QA")
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

        if (OS.mac? && @platform.downcase == "ios")
          project_directory = ((Util::Shell.exec 'find . -name "*.xcodeproj" 2>/dev/null').split /\/(?=[^\/]*$)/)[0]

          # cd to the project_directory
          Dir.chdir(project_directory)

          # set project number in project file
          pwd
          puts Util::Shell.exec "xcrun agvtool new-marketing-version #{version_number}"

          # cd back to the working_directory
          Dir.chdir(working_directory)
          # Change spec version
          change_spec_version(version_number) if has_spec_path?
        elsif @platform.downcase == 'android'
          updater = [
              VersionUpdate::Gradle.new(@repository_root)
            ].find { |candidate| candidate.supports? }

          updater.update_version version_number

        elsif @platform.downcase == 'ruby-gem'
          file = Dir["#{Util::Git.repository_root}/*.gemspec"].first
          if file
            file_text = File.read(file)
            File.open(file, "w") {|gemspec| gemspec.puts file_text.gsub(/(?<!_)version(.*)=(.*)['|"]/, "version     = '#{version_number}'")}
          end
        end

        # Create a new build commit, push to QA
        puts Util::Git.create_commit( "Update version number to #{version_number} for delivery to QA", story)
        puts Util::Shell.exec "git push"

        # Create release tag
        #create_release_tag(version_number)

        #Created tag should be pushed to private Podspec repo
        if has_spec_path? && @platform == "ios"
          puts Util::Shell.exec "git checkout #{version_number}"
          puts Util::Shell.exec "pod repo push V2PodSpecs #{@configuration.pconfig["spec"]["spec-path"]}"
          puts Util::Shell.exec "git checkout develop"
        end

        #checkout develop branch
        puts Util::Shell.exec "git checkout #{current_branch}"

        #add story name as one of the labels for the story
        labels = story.labels.map(&:name)
        labels << story.name unless labels.include?(story.name)
        puts "labels: #{labels.join(', ')}"
        story.add_labels(*labels) unless labels.include?(story.name)

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
          labels = story.labels.map(&:name)
          origin_labels = labels.dup
          labels << release_story.name
          labels.uniq!

          unless origin_labels.empty?
            if origin_labels.to_s.scan(/b\d{1}/).size > origin_labels.to_s.scan(/v\d{1}/).size
              story.add_labels(*labels)
              puts story.id
            end
          end
        }
      end

      def included_stories(project, release_story)
        project.stories filter: "current_state:delivered type:bug,chore,feature -id:#{release_story.id}"
      end

      def place_version_release(release_story)
        not_accepted_releases     = @project.stories(filter: "current_state:unstarted type:release")
        not_accepted_releases_ids = not_accepted_releases.map(&:id)
        unless (not_accepted_releases_ids.include?(release_story.id))
          not_accepted_releases     << release_story
          not_accepted_releases_ids << release_story.id
        end
        specified_pt_story = @project.stories(filter: "current_state:unstarted,started,finished,delivered,rejected").first
        last_accepted_release_story = @project.stories(filter: "current_state:accepted type:release").last
        if not_accepted_releases.size > 1
          release_story.after_id  = not_accepted_releases[-2].id
          release_story.save
        elsif !specified_pt_story.nil?
          release_story.before_id = specified_pt_story.id
          release_story.save
        end
      end

      def pull_out_rejected_stories(release_story)
        rejected_stories = @project.stories(filter: "current_state:rejected type:bug,chore,feature")
        rejected_stories.each do |rejected_story|
          rejected_stories.after_id = release_story.id
          rejected_stories.save
        end
      end

      def has_spec_path?
        config_file_path = "#{Util::Git.repository_root}/.v2gpti/config"
        config_file_text = File.read(config_file_path)
        spec_pattern_check = /spec-path(.*)=/.match("#{config_file_text}")
        if spec_pattern_check.nil?
          return false
        else
          spec_file_path = @configuration.pconfig["spec"]["spec-path"]
          return !spec_file_path.nil?
        end
      end

      def change_spec_version(version_number)
        spec_file_path = "#{Util::Git.repository_root}/#{@configuration.pconfig["spec"]["spec-path"]}"
        spec_file_text = File.read(spec_file_path)
        File.open(spec_file_path, "w") {|file| file.puts spec_file_text.gsub(/(?<!_)version(.*)=(.*)['|"]/, "version     = '#{version_number}'")}
      end

      def create_release_tag(version_number)
        Util::Shell.exec "git tag -a #{version_number} -m \"release #{version_number}\""
        puts Util::Shell.exec "git push origin #{version_number}"
      end

    end

  end
end
