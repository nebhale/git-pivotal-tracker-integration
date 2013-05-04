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

require 'git-pivotal-tracker-integration/version-update/version_update'

# A version updater for dealing with _typical_ Gradle projects.  This updater
# assumes that the version of the current project is stored within a
# +gradle.properties+ file in the root of the repository.  This properties
# file should have an entry with a key of +version+ and version number as the key.
class GitPivotalTrackerIntegration::VersionUpdate::Gradle

  # Creates an instance of this updater
  #
  # @param [String] root The root of the repository
  def initialize(root)
    @gradle_properties = File.expand_path 'gradle.properties', root

    if File.exist? @gradle_properties
      groups = nil
      File.open(@gradle_properties, 'r') do |file|
        groups = file.read().scan(/version[=:](.*)/)
      end
      @version = groups[0] ? groups[0][0]: nil
    end
  end

  # Whether this updater supports updating this project
  #
  # @return [Boolean] +true+ if a valid version number was found on
  #   initialization, +false+ otherwise
  def supports?
    !@version.nil?
  end

  # The current version of the project
  #
  # @return [String] the current version of the project
  def current_version
    @version
  end

  # Update the version of the project
  #
  # @param [String] new_version the version to update the project to
  # @return [void]
  def update_version(new_version)
    contents = File.read(@gradle_properties)
    contents = contents.gsub(/(version[=:])#{@version}/, "\\1#{new_version}")
    File.open(@gradle_properties, 'w') { |file| file.write(contents) }
  end

end
