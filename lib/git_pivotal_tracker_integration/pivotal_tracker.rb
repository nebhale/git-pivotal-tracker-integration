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
      @api_token = api_token
    end

    def projects
      get '/projects', fields: 'id,name'
    end

    def stories(project_id)
      get "/projects/#{project_id}/stories", fields: 'comments,description,id,name,story_type', limit: 5, with_state: 'unstarted'
    end

    ROOT = 'https://www.pivotaltracker.com/services/v5'.freeze

    private_constant :ROOT

    private

    def get(path, params = {})
      response = RestClient.get "#{ROOT}/#{path}", params: params, accept: 'json', X_TrackerToken: @api_token
      JSON.parse(response.body)
    rescue RestClient::Exception => e
      payload = JSON.parse(e.http_body)
      raise "#{payload['error']} #{payload['requirement']} #{payload['possible_fix']}"
    end

  end

end
