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

# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name        = "git-pivotal-tracker-integration"
  s.version     = "1.0.0"
  s.summary     = "Git commands for integration with Pivotal Tracker"
  s.description = File.read("README.md")
  s.authors     = ["Ben Hale"]
  s.email       = "nebhale@nebhale.com"
  s.homepage    = "https://github.com/nebhale/git-pivotal-tracker-integration"
  s.license     = 'Apache-2.0'

  s.extra_rdoc_files = %w(README.md LICENSE NOTICE)
  s.files            = %w(LICENSE NOTICE README.md) + Dir["lib/**/*.rb"] + Dir["lib/**/*.sh"] + Dir["bin/*"]
  s.executables      = Dir["bin/*"].map { |f| File.basename f }

  s.required_ruby_version = ">= 2.0.0"

  s.add_dependency "highline",        "~> 1.6.16"
  s.add_dependency "pivotal-tracker", "~> 0.5.10"

  s.add_development_dependency "bundler", "~> 1.3"
  s.add_development_dependency "rake"

end
