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

require "git-pivotal-tracker-integration/base"
require "highline/import"

class Start < Base

  def initialize(args)
    super()

    project = PivotalTracker::Project.find PivotalConfiguration.project_id

    if args[0] =~ /[[:digit:]]/
      @story = project.stories.find(args[0].to_i)
    elsif args[0] =~ /[[:alpha:]]/
      @story = choose do |menu|
        menu.prompt = "Choose story to start: "

        project.stories.all(
          :story_type => args[0],
          :current_state => ["unstarted", "unscheduled"],
          :limit => 5
        ).each do |story|
          menu.choice(story.name) { story }
        end
      end

      puts
    else
      @story = choose do |menu|
        menu.prompt = "Choose story to start: "

        project.stories.all(
          :current_state => ["unstarted", "unscheduled"],
          :limit => 5
        ).each do |story|
          menu.choice("%-7s %s" % [story.story_type.upcase, story.name]) { story }
        end
      end

      puts
    end
  end

  def run
    print_info @story
    branch_name = branch_name @story
    create_branch @story, branch_name
    add_commit_hook
    start_on_tracker @story
  end

  private

  @@LABEL_WIDTH = 13

  @@CONTENT_WIDTH = HighLine.new.output_cols - @@LABEL_WIDTH

  def print_info(story)
    print_label "Title"
    print_value story.name

    print_label "Description"
    print_value story.description

    PivotalTracker::Note.all(story).sort_by { |note| note.noted_at }.each_with_index do |note, index|
      print_label "Note #{index}"
      print_value note.text
    end

    puts
  end

  def print_label(label)
    print "%#{@@LABEL_WIDTH}s" % ["#{label}: "]
  end

  def print_value(value)
    if value.nil? || value.empty?
      puts ""
    else
      value.scan(/\S.{0,#{@@CONTENT_WIDTH - 2}}\S(?=\s|$)|\S+/).each_with_index do |line, index|
        if index == 0
          puts line
        else
          puts "%#{@@LABEL_WIDTH}s%s" % ["", line]
        end
      end
    end
  end

  def branch_name(story)
    branch = "#{story.id}-" + ask("Enter branch name (#{story.id}-<branch-name>): ")
    puts
    branch
  end

  def create_branch(story, development_branch)
    merge_target_branch = current_branch

    print "Pulling #{merge_target_branch}... "
    `git pull --quiet --ff-only`
    if $?.exitstatus != 0
      abort "FAIL"
    else
      puts "OK"
    end

    print "Creating and checking out #{development_branch}... "
    `git checkout --quiet -b #{development_branch}`
    if $?.exitstatus != 0
      abort "FAIL"
    end

    PivotalConfiguration.merge_target = merge_target_branch
    if $?.exitstatus != 0
      abort "FAIL"
    end

    PivotalConfiguration.story_id = story.id
    if $?.exitstatus != 0
      abort "FAIL"
    else
      puts "OK"
    end
  end

  def add_commit_hook
    repository_root = File.expand_path Dir.pwd

    until Dir.entries(repository_root).any? { |child| child =~ /.git/ }
      repository_root = File.expand_path("..", repository_root)
    end

    commit_hook = File.join(repository_root, ".git", "hooks", "prepare-commit-msg")
    if !File.exist? commit_hook
      print "Creating commit hook... "

      File.open(File.join(File.dirname(__FILE__), "prepare-commit-msg.sh"), "r") do |source|
        File.open(commit_hook, "w") do |target|
          target.write(source.read)
          target.chmod(0755)
        end
      end

      puts "OK"
    end
  end

  def start_on_tracker(story)
    print "Starting story on Pivotal Tracker... "
    story.update(:current_state => "started")
    puts "OK"
  end

end
