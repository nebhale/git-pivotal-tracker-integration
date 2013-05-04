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

require 'spec_helper'
require 'git-pivotal-tracker-integration/version-update/gradle'

describe GitPivotalTrackerIntegration::VersionUpdate::Gradle do

  it 'should not support if there is no gradle.properties file' do
    Dir.mktmpdir do |root|
      updater = GitPivotalTrackerIntegration::VersionUpdate::Gradle.new(root)

      expect(updater.supports?).to be_false
    end
  end

  it 'should not support if there is no version in the gradle.properties file' do
    Dir.mktmpdir do |root|
      gradle_properties = File.expand_path 'gradle.properties', root
      File.open(gradle_properties, 'w') { |file| file.write 'foo=bar' }

      updater = GitPivotalTrackerIntegration::VersionUpdate::Gradle.new(root)

      expect(updater.supports?).to be_false
    end
  end

  it 'should support if there is a version in the gradle.properties file' do
    Dir.mktmpdir do |root|
      gradle_properties = File.expand_path 'gradle.properties', root
      File.open(gradle_properties, 'w') { |file| file.write 'version=1' }

      updater = GitPivotalTrackerIntegration::VersionUpdate::Gradle.new(root)

      expect(updater.supports?).to be_true
    end
  end

  it 'returns the current version' do
    Dir.mktmpdir do |root|
      gradle_properties = File.expand_path 'gradle.properties', root
      File.open(gradle_properties, 'w') { |file| file.write 'version=1' }

      updater = GitPivotalTrackerIntegration::VersionUpdate::Gradle.new(root)

      expect(updater.current_version).to eq('1')
    end
  end

  it 'returns the current version' do
    Dir.mktmpdir do |root|
      gradle_properties = File.expand_path 'gradle.properties', root
      File.open(gradle_properties, 'w') { |file| file.write 'version=1' }

      updater = GitPivotalTrackerIntegration::VersionUpdate::Gradle.new(root)

      updater.update_version '2'

      File.open(gradle_properties, 'r') { |file| expect(file.read).to eq('version=2') }
    end
  end
end
