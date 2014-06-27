# Git Pivotal Tracker Integration
# Copyright (c) the original author or authors.
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


    Gem::Specification.new do |s|
      s.name        = 'v2gpti'
      s.version     = '1.1.2'
      s.summary     = 'Git commands for integration with Pivotal Tracker'
      s.description = 'Provides a set of additional Git commands to help developers when working with Pivotal Tracker'
      s.authors     = ['Ben Hale', 'Jeff Wolski']
      s.email       = 'jeff@xxxxxxxxx.com'
      s.homepage    = 'https://github.com/v2dev/V2GPTI'
      s.license     = 'Apache-2.0'

      s.files            = %w(LICENSE NOTICE README.md) + Dir['lib/**/*.rb'] + Dir['lib/**/*.sh'] + Dir['bin/*']
      s.executables      = Dir['bin/*'].map { |f| File.basename f }
      s.test_files       = Dir['spec/**/*_spec.rb']

      s.required_ruby_version = '>= 1.9'

      s.add_dependency 'highline', '~> 1.6'
      s.add_dependency 'pivotal-tracker', '~> 0.5'
      s.add_dependency 'parseconfig', '~> 1.0'
      s.add_dependency 'faraday', '~> 0.9.0'
      s.add_dependency 'awesome_print', '~> 1.1.0'
      s.add_dependency 'json', '~> 1.8.0'
      s.add_dependency  'logger', '~> 1.2.8'
      s.add_dependency  'jazor', '~> 0.1.8'

      s.add_development_dependency 'bundler', '~> 1.3'
      s.add_development_dependency 'rake', '~> 10.0'
      s.add_development_dependency 'redcarpet', '~> 2.2'
      s.add_development_dependency 'rspec', '~> 2.13'
      s.add_development_dependency 'simplecov', '~> 0.7'
      s.add_development_dependency 'yard', '~> 0.8'

end
