# Git Pivotal Tracker Integration
# Copyright 2013-2016 the original author or authors.
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

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'git_pivotal_tracker_integration/version'

Gem::Specification.new do |s|
  s.name        = 'git-pivotal-tracker-integration'
  s.version     = GitPivotalTrackerIntegration::VERSION
  s.summary     = 'Git commands for integration with Pivotal Tracker'
  s.description = 'Provides a set of additional Git commands to help developers when working with Pivotal Tracker'
  s.authors     = ['Ben Hale']
  s.email       = 'nebhale@nebhale.com'
  s.homepage    = 'https://github.com/nebhale/git-pivotal-tracker-integration'
  s.license     = 'Apache-2.0'

  s.files            = %w(LICENSE NOTICE README.md) + Dir['lib/**/*.rb']
  s.executables      = Dir['bin/*'].map { |f| File.basename f }
  s.test_files       = Dir['spec/**/*_spec.rb']

  s.required_ruby_version = '>= 2.2.5'

  s.add_dependency 'commander',   '~> 4.4'
  s.add_dependency 'highline',    '~> 1.7'
  s.add_dependency 'rest-client', '~> 1.8'
  s.add_dependency 'rugged',      '~> 0.24'

  s.add_development_dependency 'bundler',       '~> 1.12'
  s.add_development_dependency 'rake',          '~> 11.1'
  s.add_development_dependency 'rspec',         '~> 3.4'
  s.add_development_dependency 'rubocop',       '~> 0.39'
  s.add_development_dependency 'rubocop-rspec', '~> 1.4'

end
