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
require "rugged"

class Start < Base
  def initialize(args)
    super()

    if args[0] =~ /[[:digit:]]/
      @story = @project.stories.find(args[0].to_i)
    elsif args[0] =~ /[[:alpha:]]/
      @story = choose do |menu|
        menu.prompt = "Choose story to start: "

        @project.stories.all(
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

        @project.stories.all(
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
    puts "      Title: #{@story.name}"
    puts "Description: #{@story.description}"
    puts

    branch = "#{@story.id}-" + ask("Enter branch name (#{@story.id}-<branch-name>): ")
    puts

    puts branch
    Rugged::Remote.each(@repository) do |remote|
      puts remote
    end
  end

end
