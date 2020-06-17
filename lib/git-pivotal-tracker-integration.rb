
# dependencies
require 'rubygems'
require 'fileutils'
require 'time'
require 'highline/import'
require 'parseconfig'
require 'logger'
require 'os'

ROOT_PATH         = File.dirname(File.expand_path(__FILE__))
TRACKER_API_HOME  = "#{ROOT_PATH}/../tracker_api"

$LOAD_PATH << "#{TRACKER_API_HOME}/lib"

require "#{TRACKER_API_HOME}/lib/tracker_api"


module GitPivotalTrackerIntegration
  module Command
    autoload :Base,           'git-pivotal-tracker-integration/command/base'
    autoload :Configuration,  'git-pivotal-tracker-integration/command/configuration'
    autoload :Deliver,        'git-pivotal-tracker-integration/command/deliver'
    autoload :Finish,         'git-pivotal-tracker-integration/command/finish'
    autoload :Newbug,         'git-pivotal-tracker-integration/command/newbug'
    autoload :Newfeature,     'git-pivotal-tracker-integration/command/newfeature'
    autoload :Release,        'git-pivotal-tracker-integration/command/release'
    autoload :Report,         'git-pivotal-tracker-integration/command/report'
    autoload :Start,          'git-pivotal-tracker-integration/command/start'
  end

  module Util
    autoload :Git,    'git-pivotal-tracker-integration/util/git'
    autoload :Shell,  'git-pivotal-tracker-integration/util/shell'
    autoload :Story,  'git-pivotal-tracker-integration/util/story'
  end

  module VersionUpdate
    autoload :Gradle, 'git-pivotal-tracker-integration/version-update/gradle'
  end
end

autoload :Toggl,          'git-pivotal-tracker-integration/util/togglV8'
autoload :TogglException, 'git-pivotal-tracker-integration/util/togglV8'
