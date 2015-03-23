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
  module VersionUpdate

    # A version updater for dealing with _typical_ Gradle projects.  This updater
    # assumes that the version of the current project is stored within a
    # +gradle.properties+ file in the root of the repository.  This properties
    # file should have an entry with a key of +version+ and version number as the key.
    class Gradle

      # Creates an instance of this updater
      #
      # @param [String] root The root of the repository
      def initialize(root)
        @gradle_file = File.expand_path 'build.gradle', root
      end

      # Update the version of the project
      #
      # @param [String] new_version the version to update the project to
      # @return [void]
      def update_dev_version(new_version)
        update_version('DEV', 'SNAPSHOT', new_version)
      end

      def update_qa_version(new_version)
        update_version('QA', 'SNAPSHOT', new_version)
      end

      def update_uat_version(new_version)
        update_version('UAT', 'UAT', new_version)
      end

      def update_prod_version(new_version)
        update_version('PROD', 'PROD', new_version)
      end

      private

      def update_version(version_type, new_name, new_version)
        content     = File.read(@gradle_file)
        new_content = content.gsub(/productFlavors.*?#{version_type}.*?versionCode( )*=( )*(.*?)versionName( )*=( )*(.*?\s)/m) do |match|
            version_code = $3.strip
            version_name = $6.strip
            match.gsub(version_code, new_version).gsub(version_name, "\"#{new_name}\"")
        end

        File.open(@gradle_file, 'w') { |file| file.write(new_content) }
      end

    end

  end
end
