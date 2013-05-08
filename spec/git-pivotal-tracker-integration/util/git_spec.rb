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
require 'git-pivotal-tracker-integration/util/git'
require 'git-pivotal-tracker-integration/util/shell'

describe GitPivotalTrackerIntegration::Util::Git do

  before do
    $stdout = StringIO.new
    $stderr = StringIO.new
  end

  it 'should return the current branch name' do
    GitPivotalTrackerIntegration::Util::Shell.should_receive(:exec).with('git branch').and_return("   master\n * dev_branch")

    current_branch = GitPivotalTrackerIntegration::Util::Git.branch_name

    expect(current_branch).to eq('dev_branch')
  end

  it 'should return the repository root' do
    Dir.mktmpdir do |root|
      child_directory = File.expand_path 'child', root
      Dir.mkdir child_directory

      git_directory = File.expand_path '.git', root
      Dir.mkdir git_directory

      Dir.should_receive(:pwd).and_return(child_directory)

      repository_root = GitPivotalTrackerIntegration::Util::Git.repository_root

      expect(repository_root).to eq(root)
    end
  end

  it 'should raise an error there is no repository root' do
    Dir.mktmpdir do |root|
      child_directory = File.expand_path 'child', root
      Dir.mkdir child_directory

      Dir.should_receive(:pwd).and_return(child_directory)

      expect { GitPivotalTrackerIntegration::Util::Git.repository_root }.to raise_error
    end
  end

  it 'should get configuration when :branch scope is specified' do
    GitPivotalTrackerIntegration::Util::Git.should_receive(:branch_name).and_return('test_branch_name')
    GitPivotalTrackerIntegration::Util::Shell.should_receive(:exec).with('git config branch.test_branch_name.test_key', false).and_return('test_value')

    value = GitPivotalTrackerIntegration::Util::Git.get_config 'test_key', :branch

    expect(value).to eq('test_value')
  end

  it 'should get configuration when :inherited scope is specified' do
    GitPivotalTrackerIntegration::Util::Shell.should_receive(:exec).with('git config test_key', false).and_return('test_value')

    value = GitPivotalTrackerIntegration::Util::Git.get_config 'test_key', :inherited

    expect(value).to eq('test_value')
  end

  it 'should raise an error when an unknown scope is specified (get)' do
    expect { GitPivotalTrackerIntegration::Util::Git.get_config 'test_key', :unknown }.to raise_error
  end

  it 'should set configuration when :branch scope is specified' do
    GitPivotalTrackerIntegration::Util::Git.should_receive(:branch_name).and_return('test_branch_name')
    GitPivotalTrackerIntegration::Util::Shell.should_receive(:exec).with('git config --local branch.test_branch_name.test_key test_value')

    GitPivotalTrackerIntegration::Util::Git.set_config 'test_key', 'test_value', :branch
  end

  it 'should set configuration when :global scope is specified' do
    GitPivotalTrackerIntegration::Util::Shell.should_receive(:exec).with('git config --global test_key test_value')

    GitPivotalTrackerIntegration::Util::Git.set_config 'test_key', 'test_value', :global
  end

  it 'should set configuration when :local scope is specified' do
    GitPivotalTrackerIntegration::Util::Shell.should_receive(:exec).with('git config --local test_key test_value')

    GitPivotalTrackerIntegration::Util::Git.set_config 'test_key', 'test_value', :local
  end

  it 'should raise an error when an unknown scope is specified (set)' do
    expect { GitPivotalTrackerIntegration::Util::Git.set_config 'test_key', 'test_value', :unknown }.to raise_error
  end

  it 'should create a branch and set the root_branch and root_remote properties on it' do
    GitPivotalTrackerIntegration::Util::Git.should_receive(:branch_name).and_return('master')
    GitPivotalTrackerIntegration::Util::Git.should_receive(:get_config).with('remote', :branch).and_return('origin')
    GitPivotalTrackerIntegration::Util::Shell.should_receive(:exec).with('git pull --quiet --ff-only')
    GitPivotalTrackerIntegration::Util::Shell.should_receive(:exec).and_return('git checkout --quiet -b dev_branch')
    GitPivotalTrackerIntegration::Util::Git.should_receive(:set_config).with('root-branch', 'master', :branch)
    GitPivotalTrackerIntegration::Util::Git.should_receive(:set_config).with('root-remote', 'origin', :branch)

    GitPivotalTrackerIntegration::Util::Git.create_branch 'dev_branch'
  end

  it 'should not add a hook if it already exists' do
    Dir.mktmpdir do |root|
      GitPivotalTrackerIntegration::Util::Git.should_receive(:repository_root).and_return(root)
      hook = "#{root}/.git/hooks/prepare-commit-msg"
      File.should_receive(:exist?).with(hook).and_return(true)

      GitPivotalTrackerIntegration::Util::Git.add_hook 'prepare-commit-msg', __FILE__

      File.should_receive(:exist?).and_call_original
      expect(File.exist?(hook)).to be_false
    end
  end

  it 'should add a hook if it does not exist' do
    Dir.mktmpdir do |root|
      GitPivotalTrackerIntegration::Util::Git.should_receive(:repository_root).and_return(root)
      hook = "#{root}/.git/hooks/prepare-commit-msg"
      File.should_receive(:exist?).with(hook).and_return(false)

      GitPivotalTrackerIntegration::Util::Git.add_hook 'prepare-commit-msg', __FILE__

      File.should_receive(:exist?).and_call_original
      expect(File.exist?(hook)).to be_true
    end
  end

  it 'should add a hook if it already exists and overwrite is true' do
    Dir.mktmpdir do |root|
      GitPivotalTrackerIntegration::Util::Git.should_receive(:repository_root).and_return(root)
      hook = "#{root}/.git/hooks/prepare-commit-msg"

      GitPivotalTrackerIntegration::Util::Git.add_hook 'prepare-commit-msg', __FILE__, true

      File.should_receive(:exist?).and_call_original
      expect(File.exist?(hook)).to be_true
    end
  end

  it 'should fail if root tip and common_ancestor do not match' do
    GitPivotalTrackerIntegration::Util::Git.should_receive(:branch_name).and_return('development_branch')
    GitPivotalTrackerIntegration::Util::Git.should_receive(:get_config).with('root-branch', :branch).and_return('master')
    GitPivotalTrackerIntegration::Util::Shell.should_receive(:exec).with('git checkout --quiet master')
    GitPivotalTrackerIntegration::Util::Shell.should_receive(:exec).with('git pull --quiet --ff-only')
    GitPivotalTrackerIntegration::Util::Shell.should_receive(:exec).with('git checkout --quiet development_branch')
    GitPivotalTrackerIntegration::Util::Shell.should_receive(:exec).with('git rev-parse master').and_return('root_tip')
    GitPivotalTrackerIntegration::Util::Shell.should_receive(:exec).with('git merge-base master development_branch').and_return('common_ancestor')

    lambda { GitPivotalTrackerIntegration::Util::Git.trivial_merge? }.should raise_error(SystemExit)

    expect($stderr.string).to match(/FAIL/)
  end

  it 'should pass if root tip and common ancestor match' do
    GitPivotalTrackerIntegration::Util::Git.should_receive(:branch_name).and_return('development_branch')
    GitPivotalTrackerIntegration::Util::Git.should_receive(:get_config).with('root-branch', :branch).and_return('master')
    GitPivotalTrackerIntegration::Util::Shell.should_receive(:exec).with('git checkout --quiet master')
    GitPivotalTrackerIntegration::Util::Shell.should_receive(:exec).with('git pull --quiet --ff-only')
    GitPivotalTrackerIntegration::Util::Shell.should_receive(:exec).with('git checkout --quiet development_branch')
    GitPivotalTrackerIntegration::Util::Shell.should_receive(:exec).with('git rev-parse master').and_return('HEAD')
    GitPivotalTrackerIntegration::Util::Shell.should_receive(:exec).with('git merge-base master development_branch').and_return('HEAD')

    GitPivotalTrackerIntegration::Util::Git.trivial_merge?

    expect($stdout.string).to match(/OK/)
  end

  it 'should merge and delete branches' do
    GitPivotalTrackerIntegration::Util::Git.should_receive(:branch_name).and_return('development_branch')
    GitPivotalTrackerIntegration::Util::Git.should_receive(:get_config).with('root-branch', :branch).and_return('master')
    GitPivotalTrackerIntegration::Util::Shell.should_receive(:exec).with('git checkout --quiet master')
    GitPivotalTrackerIntegration::Util::Shell.should_receive(:exec).with("git merge --quiet --no-ff -m \"Merge development_branch to master\n\n[Completes #12345678]\" development_branch")
    GitPivotalTrackerIntegration::Util::Shell.should_receive(:exec).with('git branch --quiet -D development_branch')

    GitPivotalTrackerIntegration::Util::Git.merge PivotalTracker::Story.new(:id => 12345678), nil
  end

  it 'should suppress Completes statement' do
    GitPivotalTrackerIntegration::Util::Git.should_receive(:branch_name).and_return('development_branch')
    GitPivotalTrackerIntegration::Util::Git.should_receive(:get_config).with('root-branch', :branch).and_return('master')
    GitPivotalTrackerIntegration::Util::Shell.should_receive(:exec).with('git checkout --quiet master')
    GitPivotalTrackerIntegration::Util::Shell.should_receive(:exec).with("git merge --quiet --no-ff -m \"Merge development_branch to master\n\n[#12345678]\" development_branch")
    GitPivotalTrackerIntegration::Util::Shell.should_receive(:exec).with('git branch --quiet -D development_branch')

    GitPivotalTrackerIntegration::Util::Git.merge PivotalTracker::Story.new(:id => 12345678), true
  end

  it 'should push changes without refs' do
    GitPivotalTrackerIntegration::Util::Git.should_receive(:get_config).with('remote', :branch).and_return('origin')
    GitPivotalTrackerIntegration::Util::Shell.should_receive(:exec).with('git push --quiet origin ')

    GitPivotalTrackerIntegration::Util::Git.push
  end

  it 'should push changes with refs' do
    GitPivotalTrackerIntegration::Util::Git.should_receive(:get_config).with('remote', :branch).and_return('origin')
    GitPivotalTrackerIntegration::Util::Shell.should_receive(:exec).with('git push --quiet origin foo bar')

    GitPivotalTrackerIntegration::Util::Git.push 'foo', 'bar'
  end

  it 'should create a commit' do
    story = PivotalTracker::Story.new(:id => 123456789)
    GitPivotalTrackerIntegration::Util::Shell.should_receive(:exec).with("git commit --quiet --all --allow-empty --message \"test_message\n\n[#123456789]\"")

    GitPivotalTrackerIntegration::Util::Git.create_commit 'test_message', story
  end

  it 'should create a release tag' do
    story = PivotalTracker::Story.new(:id => 123456789)
    GitPivotalTrackerIntegration::Util::Git.should_receive(:branch_name).and_return('master')
    GitPivotalTrackerIntegration::Util::Git.should_receive(:create_branch).with('pivotal-tracker-release', false)
    GitPivotalTrackerIntegration::Util::Git.should_receive(:create_commit).with('1.0.0.RELEASE Release', story)
    GitPivotalTrackerIntegration::Util::Shell.should_receive(:exec).with('git tag v1.0.0.RELEASE')
    GitPivotalTrackerIntegration::Util::Shell.should_receive(:exec).with('git checkout --quiet master')
    GitPivotalTrackerIntegration::Util::Shell.should_receive(:exec).with('git branch --quiet -D pivotal-tracker-release')

    GitPivotalTrackerIntegration::Util::Git.create_release_tag '1.0.0.RELEASE', story
  end
end
