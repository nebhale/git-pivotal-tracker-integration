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
require "git-pivotal-tracker-integration/finish"

describe Finish do
  before do
    PivotalConfiguration.should_receive(:api_token).and_return("test_api_token")
    PivotalTracker::Client.stub!(:token, :use_ssl)

    $stdout = StringIO.new
    $stderr = StringIO.new
    @finish = Finish.new
   end

  before do
    PivotalConfiguration.should_receive(:merge_remote).and_return("origin")
    PivotalConfiguration.should_receive(:merge_target).and_return("master")
    PivotalConfiguration.should_receive(:story_id).and_return("test_story_id")
    @finish.should_receive(:current_branch).and_return("dev_branch")
  end

  it "should fail if remote tip and local tip do not match" do
    @finish.should_receive(:exec).with("git fetch origin")
    @finish.should_receive(:exec).with("git rev-parse origin/master").and_return("remote_tip")
    @finish.should_receive(:exec).with("git rev-parse master").and_return("local_tip")
    @finish.should_receive(:exec).with("git merge-base master dev_branch").and_return("common_ancestor")

    lambda { @finish.run }.should raise_error(SystemExit)

    expect($stderr.string).to match(/FAIL/)
  end

  it "should fail if local tip and common ancestor do not match" do
    @finish.should_receive(:exec).with("git fetch origin")
    @finish.should_receive(:exec).with("git rev-parse origin/master").and_return("HEAD")
    @finish.should_receive(:exec).with("git rev-parse master").and_return("HEAD")
    @finish.should_receive(:exec).with("git merge-base master dev_branch").and_return("common_ancestor")

    lambda { @finish.run }.should raise_error(SystemExit)

    expect($stderr.string).to match(/FAIL/)
  end

  it "should pass if remote tip, local tip, and common ancestor all match" do
    @finish.should_receive(:exec).with("git fetch origin")
    @finish.should_receive(:exec).with("git rev-parse origin/master").and_return("HEAD")
    @finish.should_receive(:exec).with("git rev-parse master").and_return("HEAD")
    @finish.should_receive(:exec).with("git merge-base master dev_branch").and_return("HEAD")
    @finish.should_receive(:merge_branch)
    @finish.should_receive(:delete_branch)
    @finish.should_receive(:push)

    @finish.run

    expect($stdout.string).to match(/OK/)
  end

  it "should merge branches" do
    @finish.should_receive(:check_trivial_merge)
    @finish.should_receive(:exec).with("git checkout --quiet master")
    @finish.should_receive(:exec).with("git merge --quiet --no-ff -m \"Merge dev_branch to master\n\n[Completes #test_story_id]\" dev_branch")
    @finish.should_receive(:delete_branch)
    @finish.should_receive(:push)

    @finish.run

    expect($stdout.string).to match(/OK/)
  end

  it "should delete development branch" do
    @finish.should_receive(:check_trivial_merge)
    @finish.should_receive(:merge_branch)
    @finish.should_receive(:exec).with("git branch -D dev_branch")
    @finish.should_receive(:push)

    @finish.run

    expect($stdout.string).to match(/OK/)
  end

  it "should push changes to remove" do
    @finish.should_receive(:check_trivial_merge)
    @finish.should_receive(:merge_branch)
    @finish.should_receive(:delete_branch)
    @finish.should_receive(:exec).with("git push --quiet origin")

    @finish.run

    expect($stdout.string).to match(/OK/)
  end
end
