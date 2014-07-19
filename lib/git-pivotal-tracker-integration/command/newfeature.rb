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

# The class that encapsulates creating a Pivotal Tracker Bug Story
class GitPivotalTrackerIntegration::Command::Newfeature < GitPivotalTrackerIntegration::Command::Base

  # Creates a Pivotal Tracker story by doing the following steps:
  # * Takes arguments from command line
  # * If arguments contains -i then it creates a feature story under icebox
  # * If arguments contains -b then it creates a feature story under backlog
  # * If arguments contains -tl then it creates a feature story at top of specified list
  # * If arguments contains -bl then it creates a feature story at bottom of specified list
  # * If arguments contains -p1 then it creates a feature story with estimate as 1 point.
  # * If arguments contains -p2 then it creates a feature story with estimate as 2 points.
  # * If arguments contains -p3 then it creates a feature story with estimate as 3 points.
  # * If there are no arguments passed then it creates a feature story in icebox top of the list if you wish to create
  def run(args)
    my_projects = PivotalTracker::Project.all
    $LOG.debug("#{self.class} in project:#{@project.name} pwd:#{(GitPivotalTrackerIntegration::Util::Shell.exec !OS.windows? ? 'pwd' : 'echo %cd%').chop} branch:#{GitPivotalTrackerIntegration::Util::Git.branch_name}")
    story = nil
    if (!args.empty? && args.any?{|arg| arg.include?("-i")})
      story = self.create_icebox_feature_story(args)
    elsif (!args.empty? && args.any?{|arg| arg.include?("-b")})
      story = self.create_backlog_feature_story(args)
	else
	  puts "\n Syntax for creating new feature story in icebox top of the list:\n git newfeature -i -tl <feature-title> \n Syntax for creating new feature story in icebox bottom of the list: \n git newfeature -i -bl <feature-title>\n"
	  puts "\n Syntax for creating new feature story in backlog top of the list:\n git newfeature -b -tl <feature-title> \n Syntax for creating new feature story in backlog bottom of the list: \n git newfeature -b -bl <feature-title>\n"
	  user_response = nil
	  while (user_response.nil? || user_response.empty?)
	  user_response = ask("\nYou have missed some parameters to pass...If you are ok with creating new feature story in icebox then enter y otherwise enter n")
	  end
	  while !(["y","n"].include?(user_response.downcase))
	  user_response = ask("\nInvalid entry...If you are ok with creating new feature story in icebox then enter y otherwise enter n")
	  end
	  if user_response.downcase == "y"
		story = self.create_icebox_feature_story(args)
	  else
	  abort "\nCheck your new feature story creation syntax and then try again"
	  end
    end
	puts "A new feature story has been created successfully with ID:#{story.id}"
  end

end
