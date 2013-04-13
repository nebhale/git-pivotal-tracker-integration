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

require "spec_helper"
require "git-pivotal-tracker-integration/base"

describe Base do
  before do
    PivotalConfiguration.should_receive(:api_token).and_return("test_api_token")
    PivotalTracker::Client.stub!(:token, :use_ssl)

    $stdout = StringIO.new
    $stderr = StringIO.new
    @base = Stub.new()
  end

  it "should return the current branch" do
    @base.should_receive(:exec).with("git branch").and_return("   master\n * dev_branch")

    current_branch = @base.current_branch_stub

    expect(current_branch).to eq("dev_branch")
  end

  it "should return result when exit code is 0" do
    @base.should_receive(:`).with("test_command").and_return("test_result")
    $?.should_receive(:exitstatus).and_return(0)

    result = @base.exec_stub "test_command"

    expect(result).to eq("test_result")
  end

  it "should abort with 'FAIL' when the exit code is not 0" do
    @base.should_receive(:`).with("test_command")
    $?.should_receive(:exitstatus).and_return(-1)

    lambda { @base.exec_stub "test_command" }.should raise_error(SystemExit)

    expect($stderr.string).to match(/FAIL/)
  end
end

class Stub < Base

  def current_branch_stub
    current_branch
  end

  def exec_stub(command)
    exec(command)
  end

end
