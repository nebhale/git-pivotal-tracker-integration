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
    PivotalConfiguration.should_receive(:merge_remote).and_return("test_merge_remote")
    PivotalConfiguration.should_receive(:merge_target).and_return("test_merge_target")
    PivotalConfiguration.should_receive(:story_id).and_return("test_story_id")
    PivotalTracker::Client.stub!(:token, :use_ssl)

    @finish = Finish.new
    @finish.should_receive(:current_branch).and_return("test_branch")
    $stdout = StringIO.new
    $stderr = StringIO.new
  end

  it "should fail if fetch fails" do
    @finish.should_receive(:`).with("git fetch test_merge_remote")
    $?.should_receive(:exitstatus).and_return(-1)

    lambda { @finish.run }.should raise_error(SystemExit)
  end

  it "should fail if remote tip determination fails" do
    @finish.should_receive(:`).with("git fetch test_merge_remote")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git rev-parse test_merge_remote/test_merge_target")
    $?.should_receive(:exitstatus).and_return(-1)

    lambda { @finish.run }.should raise_error(SystemExit)
  end

  it "should fail if local tip determination fails" do
    @finish.should_receive(:`).with("git fetch test_merge_remote")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git rev-parse test_merge_remote/test_merge_target").and_return("test_remote_tip")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git rev-parse test_merge_target")
    $?.should_receive(:exitstatus).and_return(-1)

    lambda { @finish.run }.should raise_error(SystemExit)
  end

  it "should fail if local and remote tips don't match" do
    @finish.should_receive(:`).with("git fetch test_merge_remote")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git rev-parse test_merge_remote/test_merge_target").and_return("test_remote_tip")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git rev-parse test_merge_target").and_return("test_local_tip")
    $?.should_receive(:exitstatus).and_return(0)

    lambda { @finish.run }.should raise_error(SystemExit)
  end

  it "should fail if common ancestor determination fails" do
    @finish.should_receive(:`).with("git fetch test_merge_remote")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git rev-parse test_merge_remote/test_merge_target").and_return("test_tip")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git rev-parse test_merge_target").and_return("test_tip")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git merge-base test_merge_target test_branch")
    $?.should_receive(:exitstatus).and_return(-1)

    lambda { @finish.run }.should raise_error(SystemExit)
  end

  it "should fail if tip and common ancestor don't match" do
    @finish.should_receive(:`).with("git fetch test_merge_remote")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git rev-parse test_merge_remote/test_merge_target").and_return("test_tip")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git rev-parse test_merge_target").and_return("test_tip")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git merge-base test_merge_target test_branch").and_return("common_ancestor")
    $?.should_receive(:exitstatus).and_return(0)

    lambda { @finish.run }.should raise_error(SystemExit)
  end

  it "should fail if target branch checkout fails" do
    @finish.should_receive(:`).with("git fetch test_merge_remote")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git rev-parse test_merge_remote/test_merge_target").and_return("test_tip")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git rev-parse test_merge_target").and_return("test_tip")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git merge-base test_merge_target test_branch").and_return("test_tip")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git checkout --quiet test_merge_target")
    $?.should_receive(:exitstatus).and_return(-1)

    lambda { @finish.run }.should raise_error(SystemExit)
  end

  it "should fail if merging branches fails" do
    @finish.should_receive(:`).with("git fetch test_merge_remote")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git rev-parse test_merge_remote/test_merge_target").and_return("test_tip")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git rev-parse test_merge_target").and_return("test_tip")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git merge-base test_merge_target test_branch").and_return("test_tip")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git checkout --quiet test_merge_target")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git merge --quiet --no-ff -m \"Merge test_branch to test_merge_target\n\n[Completes #test_story_id]\" test_branch")
    $?.should_receive(:exitstatus).and_return(-1)

    lambda { @finish.run }.should raise_error(SystemExit)
  end

  it "should fail if development branch deletion fails" do
    @finish.should_receive(:`).with("git fetch test_merge_remote")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git rev-parse test_merge_remote/test_merge_target").and_return("test_tip")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git rev-parse test_merge_target").and_return("test_tip")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git merge-base test_merge_target test_branch").and_return("test_tip")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git checkout --quiet test_merge_target")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git merge --quiet --no-ff -m \"Merge test_branch to test_merge_target\n\n[Completes #test_story_id]\" test_branch")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git branch -D test_branch")
    $?.should_receive(:exitstatus).and_return(-1)

    lambda { @finish.run }.should raise_error(SystemExit)
  end

  it "should fail if push fails" do
    @finish.should_receive(:`).with("git fetch test_merge_remote")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git rev-parse test_merge_remote/test_merge_target").and_return("test_tip")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git rev-parse test_merge_target").and_return("test_tip")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git merge-base test_merge_target test_branch").and_return("test_tip")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git checkout --quiet test_merge_target")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git merge --quiet --no-ff -m \"Merge test_branch to test_merge_target\n\n[Completes #test_story_id]\" test_branch")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git branch -D test_branch")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git push --quiet test_merge_remote")
    $?.should_receive(:exitstatus).and_return(-1)

    lambda { @finish.run }.should raise_error(SystemExit)
  end

  it "should not fail" do
    @finish.should_receive(:`).with("git fetch test_merge_remote")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git rev-parse test_merge_remote/test_merge_target").and_return("test_tip")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git rev-parse test_merge_target").and_return("test_tip")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git merge-base test_merge_target test_branch").and_return("test_tip")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git checkout --quiet test_merge_target")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git merge --quiet --no-ff -m \"Merge test_branch to test_merge_target\n\n[Completes #test_story_id]\" test_branch")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git branch -D test_branch")
    $?.should_receive(:exitstatus).and_return(0)
    @finish.should_receive(:`).with("git push --quiet test_merge_remote")
    $?.should_receive(:exitstatus).and_return(0)

    @finish.run
  end
end
