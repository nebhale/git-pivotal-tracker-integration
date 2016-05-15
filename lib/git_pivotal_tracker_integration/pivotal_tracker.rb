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

require 'rest-client'

module GitPivotalTrackerIntegration

  class PivotalTracker

    def initialize(api_token)
      @headers = { :X_TrackerToken => api_token }
    end

    def projects
      JSON.parse(RestClient.get("#{ROOT}/projects", @headers).body)
    end

    ROOT = 'https://www.pivotaltracker.com/services/v5'.freeze

    private_constant :ROOT

  end

end
