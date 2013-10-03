require 'git-pivotal-tracker-integration/command/base'
require 'git-pivotal-tracker-integration/command/command'
require 'git-pivotal-tracker-integration/util/git'

class GitPivotalTrackerIntegration::Command::Squash < GitPivotalTrackerIntegration::Command::Base
  def run
    GitPivotalTrackerIntegration::Util::Shell.exec "sh #{File.expand_path('../squash.sh', __FILE__)}"
  end
end

