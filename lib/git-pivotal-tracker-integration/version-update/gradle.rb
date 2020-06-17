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
        @gradle_file = File.expand_path 'app/build.gradle', root
      end

      # Update the version of the project
      #
      # @param [String] new_version the version to update the project to
      # @return [void]
      def update_dev_version(new_version)
        update_version_in_sec('DEV', new_version, 'SNAPSHOT')
      end

      def update_qa_version(new_version)
        update_version_in_sec('QA', new_version, 'SNAPSHOT')
      end

      def update_uat_version(new_version)
        update_version_in_sec('UAT', qa_version_code, new_version)
      end

      def update_prod_version(new_version)
        update_version_in_sec('PROD', qa_version_code, new_version)
      end

      private

      def update_version_in_sec(section, new_code, new_version)
        content     = File.read(@gradle_file)

        new_content = update_version(content, section, 'Code', new_code)  #update versionCode
        new_content = update_version(new_content, section, 'Name', "\"#{new_version}\"") #update versionName

        File.open(@gradle_file, 'w') { |file| file.write(new_content) }
      end

      def qa_version_code
        content     = File.read(@gradle_file)
        match       = content.match(/productFlavors.*?QA.*?versionCode( )*=?( )*(.*?\s)/m)
        match[3].strip
      end

      def update_version(file_content, section, type, new_value)
        file_content.gsub(/productFlavors.*?#{section}.*?version#{type}( )*=?( )*(.*?\s)/m) do |match|
          match.gsub($3.strip, new_value)
        end
      end

    end

  end
end
