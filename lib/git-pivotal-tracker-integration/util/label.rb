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

require 'git-pivotal-tracker-integration/util/util'

# Utilities for dealing with the shell
class GitPivotalTrackerIntegration::Util::Label

  # Add labels to story if they are not already appended to story.
  #
  # @param [PivotalTracker::Story, String] labels as Strings, one label per parameter.
  # @return [boolean] Boolean defining whether story was updated or not.
  def self.add(story, *labels)
    current_labels = story.labels.split(',')
    new_labels = current_labels | labels
    if story.update(:labels => new_labels)
      puts "Updated labels on #{story.name}:"
      puts "#{current_labels} => #{new_labels}"
    else
      abort("Failed to update labels on Pivotal Tracker")
    end
  end

  # Add labels from story and remove those labels from every other story in a project.
  #
  # @param [PivotalTracker::Story, String] labels as Strings, one label per parameter.
  # @return [boolean] Boolean defining whether story was updated or not.
  def self.once(story, *labels)
    PivotalTracker::Project.find(story.project_id).stories.all.each do |other_story|
      self.remove(other_story, *labels) if story.name != other_story.name and
                                           other_story.labels and
                                           (other_story.labels.split(',') & labels).any?
    end
    self.add(story, *labels)
  end

  # Remove labels from story.
  #
  # @param [PivotalTracker::Story, String] labels as Strings, one label per parameter.
  # @return [boolean] Boolean defining whether story was updated or not.
  def self.remove(story, *labels)
    current_labels = story.labels.split(',')
    new_labels = current_labels - labels
    if story.update(:labels => new_labels)
      puts "Updated labels on #{story.name}:"
      puts "#{current_labels} => #{new_labels}"
    else
      abort("Failed to update labels on Pivotal Tracker")
    end
  end

  # Print labels from story.
  #
  # @param [PivotalTracker::Story, String] labels as Strings, one label per parameter.
  # @return [boolean] Boolean defining whether story was updated or not.
  def self.list(story)
    puts "Story labels:"
    puts story.labels.split(',')
  end
end
