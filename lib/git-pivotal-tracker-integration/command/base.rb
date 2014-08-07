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

require 'git-pivotal-tracker-integration/command/command'
require 'git-pivotal-tracker-integration/command/configuration'
require 'git-pivotal-tracker-integration/util/git'
require 'pivotal-tracker'
require 'parseconfig'
require 'logger'
require 'os'

# An abstract base class for all commands
# @abstract Subclass and override {#run} to implement command functionality
class GitPivotalTrackerIntegration::Command::Base

  # Common initialization functionality for all command classes.  This
  # enforces that:
  # * the command is being run within a valid Git repository
  # * the user has specified their Pivotal Tracker API token
  # * all communication with Pivotal Tracker will be protected with SSL
  # * the user has configured the project id for this repository
  def initialize
    self.start_logging
    self.check_version

    git_global_push_default = (GitPivotalTrackerIntegration::Util::Shell.exec "git config --global push.default", false).chomp
    if git_global_push_default != "simple"
      puts "git config --global push.default simple"
      puts GitPivotalTrackerIntegration::Util::Shell.exec "git config --global push.default simple"
    end

    @repository_root = GitPivotalTrackerIntegration::Util::Git.repository_root
    @configuration = GitPivotalTrackerIntegration::Command::Configuration.new
    @toggl = Toggl.new

    PivotalTracker::Client.token    = @configuration.api_token
    PivotalTracker::Client.use_ssl  = true

    @project = PivotalTracker::Project.find @configuration.project_id

    @platform = @configuration.platform_name

    my_projects         = PivotalTracker::Project.all
    my_all_projects_ids = Array.new
    my_projects.collect{|project| my_all_projects_ids.push project.id.to_i }
    current_project_id    = @configuration.project_id.to_i
    project_manager_name  = @configuration.pconfig["project"]["project-manager"]
    project_manager_email = @configuration.pconfig["project"]["project-manager-email"]
    project_name          = @configuration.pconfig["project"]["project-name"]
    abort "This project requires access to the Pivotal Tracker project [#{project_name} - #{current_project_id}]. Please speak with project manager [#{project_manager_name} - #{project_manager_email}] and ask him to add you to the project in Pivotal Tracker." unless my_all_projects_ids.include?(current_project_id)
  end

  def finish_toggle(configuration, time_spent)
    current_story = @configuration.story(@project)
    @toggl.create_task(parameters(configuration, time_spent))
    @toggl.create_time_entry(parameters(configuration, time_spent))
  rescue TogglException => te
    puts te.message
  end

  def start_logging
    $LOG = Logger.new("#{logger_filename}", 'weekly')
  end

  def logger_filename
    return "#{Dir.home}/.v2gpti_local.log"
  end

  def check_version
    gem_latest_version = (GitPivotalTrackerIntegration::Util::Shell.exec "gem list v2gpti --remote")[/\(.*?\)/].delete "()"
    gem_installed_version = Gem.loaded_specs["v2gpti"].version.version
    if (gem_installed_version == gem_latest_version)
        $LOG.info("v2gpti verison #{gem_installed_version} is up to date.")
    else
        $LOG.fatal("Out of date")
        abort "\n\nYou are using v2gpti version #{gem_installed_version}, but the current version is #{gem_latest_version}.\nPlease update your gem with the following command.\n\n    sudo gem update v2gpti\n\n"

    end
  end

  # The main entry point to the command's execution
  # @abstract Override this method to implement command functionality
  def run
    raise NotImplementedError
  end

  # Toggl keys
  # name              : The name of the task (string, required, unique in project)
  # pid               : project ID for the task (integer, required)
  # wid               : workspace ID, where the task will be saved (integer, project's workspace id is used when not supplied)
  # uid               : user ID, to whom the task is assigned to (integer, not required)
  # estimated_seconds : estimated duration of task in seconds (integer, not required)
  # active            : whether the task is done or not (boolean, by default true)
  # at                : timestamp that is sent in the response for PUT, indicates the time task was last updated
  # -- Additional fields --
  # done_seconds      : duration (in seconds) of all the time entries registered for this task
  # uname             : full name of the person to whom the task is assigned to
  TIMER_TOKENS = {
      "m" => (60),
      "h" => (60 * 60),
      "d" => (60 * 60 * 8) # a work day is 8 hours
  }
  def parameters(configuration, time_spent)
    current_story = configuration.story(@project)
    params = Hash.new
    params[:name] = "#{current_story.id}" + " - " + "#{current_story.name}"
    params[:estimated_seconds] = estimated_seconds current_story
    params[:pid] = configuration.toggl_project_id
    params[:uid] = @toggl.me["id"]
    params[:tags] = [current_story.story_type]
    params[:active] = false
    params[:description] = "#{current_story.id}" + " commit:" + "#{(GitPivotalTrackerIntegration::Util::Shell.exec "git rev-parse HEAD").chomp[0..6]}"
    params[:created_with] = "v2gpti"
    params[:duration] = seconds_spent(time_spent)
    params[:start] = (Time.now - params[:duration]).iso8601
    task = @toggl.get_project_task_with_name(configuration.toggl_project_id, "#{current_story.id}")
     if !task.nil?
       params[:tid] = task['id']
     end
    params
  end
  def seconds_spent(time_spent)
    seconds = 0
    time_spent.scan(/(\d+)(\w)/).each do |amount, measure|
      seconds += amount.to_i * TIMER_TOKENS[measure]
    end
    seconds
  end
  def estimated_seconds(story)
    estimate = story.estimate
    seconds = 0
    case estimate
      when 0
        estimate = 15 * 60
      when 1
        estimate = 1.25 * 60 * 60
      when 2
        estimate = 3 * 60 * 60
      when 3
        estimate = 8 * 60 * 60
      else
        estimate = -1 * 60 * 60
    end
    estimate
  end

  def create_story(args)
    story_types = {"f" => "feature", "b" => "bug", "c" => "chore"}
    new_story_type = nil
    new_story_title = nil
    new_story_estimate = -1
    args.each do |arg|
      new_story_type = story_types[arg[-1]] if arg.include? '-n'
      new_story_title = arg if arg[0] != "-"
    end

    while new_story_type.nil?
      nst = ask("Please enter f for feature, b for bug, or c for chore")
      new_story_type = story_types[nst]
    end

    while (new_story_title.nil? || new_story_title.empty?)
      new_story_title = ask("Please enter the title for this #{new_story_type}.")
    end

    while (new_story_type == "feature" && (new_story_estimate < 0 || new_story_estimate > 3))
      nse = ask("Please enter an estimate for this #{new_story_type}. (0,1,2,3)")
      if !nse.empty?
        new_story_estimate = nse.to_i
      end
    end

    new_story = PivotalTracker::Story.new
    new_story.project_id = @project.id
    new_story.story_type = new_story_type
    new_story.current_state = "unstarted"
    new_story.name = new_story_title
    if new_story_type == "feature"
      new_story.estimate = new_story_estimate
    end

    uploaded_story = new_story.create

  end

  def create_icebox_bug_story(args)
      new_bug_story_title = nil
      args.each do |arg|
          new_bug_story_title = arg if arg[0] != "-"
      end
      while (new_bug_story_title.nil? || new_bug_story_title.empty?)
          new_bug_story_title = ask("Please enter the title for this bug story")
      end
      icebox_stories = Array.new
      @project.stories.all.collect{|story| icebox_stories.push story if story.current_state == "unscheduled"}
      new_bug_story = PivotalTracker::Story.new
      new_bug_story.project_id = @project.id
      new_bug_story.story_type = "bug"
      new_bug_story.current_state = "unscheduled"
      new_bug_story.name = new_bug_story_title

      if args.any?{|arg| arg.include?("-tl") } && !(icebox_stories.empty? || icebox_stories.nil?)
          icebox_first_story = icebox_stories.first
          (new_bug_story.create).move(:before, icebox_first_story)
          elsif args.any?{|arg| arg.include?("-bl")} && !(icebox_stories.empty? || icebox_stories.nil?)
          icebox_last_story = icebox_stories.last
          (new_bug_story.create).move(:after, icebox_last_story)
          else
          new_bug_story.create
      end
  end

  def create_backlog_bug_story(args)
      new_bug_story_title = nil
      args.each do |arg|
          new_bug_story_title = arg if arg[0] != "-"
      end
      while (new_bug_story_title.nil? || new_bug_story_title.empty?)
          new_bug_story_title = ask("Please enter the title for this bug story")
      end
      backlog_stories = Array.new
      @project.stories.all.collect{|story| backlog_stories.push story if story.current_state == "unstarted" && story.story_type != "release"}
      new_bug_story = PivotalTracker::Story.new
      new_bug_story.project_id = @project.id
      new_bug_story.story_type = "bug"
      new_bug_story.current_state = "unstarted"
      new_bug_story.name = new_bug_story_title
      if args.any?{|arg| arg.include?("-tl")} && !(backlog_stories.empty? || backlog_stories.nil?)
          backlog_first_story = backlog_stories.first
          (new_bug_story.create).move(:before, backlog_first_story)
          elsif args.any?{|arg| arg.include?("-bl")} && !(backlog_stories.empty? || backlog_stories.nil?)
          backlog_last_story = backlog_stories.last
          (new_bug_story.create).move(:after, backlog_last_story)
          else
          new_bug_story.create
      end
  end

  def create_icebox_feature_story(args)
      new_feature_story_title = nil
      new_feature_story_points = nil
      args.each do |arg|
          new_feature_story_title = arg if arg[0] != "-"
      end
      while (new_feature_story_title.nil? || new_feature_story_title.empty?)
          new_feature_story_title = ask("\nPlease enter the title for this feature story")
      end
      icebox_stories = Array.new
      @project.stories.all.collect{|story| icebox_stories.push story if story.current_state == "unscheduled"}
      new_feature_story = PivotalTracker::Story.new
      new_feature_story.project_id = @project.id
      new_feature_story.story_type = "feature"
      new_feature_story.current_state = "unscheduled"
      new_feature_story.name = new_feature_story_title

      args.each do |arg|
          new_feature_story_points = arg[2] if arg[0] == "-" && arg[1].downcase == "p"
      end
      while (new_feature_story_points.nil? || new_feature_story_points.empty?)
          new_feature_story_points = ask("\nPlease enter the estimate points(0/1/2/3) for this feature story.\nIf you don't want to estimate then enter n")
      end
      while (!["0","1","2","3","n"].include?(new_feature_story_points.downcase))
          new_feature_story_points = ask("\nInvalid entry...Please enter the estimate points(0/1/2/3) for this feature story.\nIf you don't want to estimate then enter n")
      end
      if new_feature_story_points.downcase == "n"
          new_feature_story.estimate = -1
          else
          new_feature_story.estimate = new_feature_story_points
      end


      if args.any?{|arg| arg.include?("-tl") } && !(icebox_stories.empty? || icebox_stories.nil?)
          icebox_first_story = icebox_stories.first
          (new_feature_story.create).move(:before, icebox_first_story)
          elsif args.any?{|arg| arg.include?("-bl")} && !(icebox_stories.empty? || icebox_stories.nil?)
          icebox_last_story = icebox_stories.last
          (new_feature_story.create).move(:after, icebox_last_story)
          else
          icebox_first_story = icebox_stories.first
          (new_feature_story.create).move(:before, icebox_first_story)
      end
  end

  def create_backlog_feature_story(args)
      new_feature_story_title = nil
      new_feature_story_points = nil
      args.each do |arg|
          new_feature_story_title = arg if arg[0] != "-"
      end
      while (new_feature_story_title.nil? || new_feature_story_title.empty?)
          new_feature_story_title = ask("\nPlease enter the title for this feature story")
      end
      backlog_stories = Array.new
      @project.stories.all.collect{|story| backlog_stories.push story if story.current_state == "unstarted" && story.story_type != "release"}
      new_feature_story = PivotalTracker::Story.new
      new_feature_story.project_id = @project.id
      new_feature_story.story_type = "feature"
      new_feature_story.current_state = "unstarted"
      new_feature_story.name = new_feature_story_title

      args.each do |arg|
          new_feature_story_points = arg[2] if arg[0] == "-" && arg[1].downcase == "p"
      end
      while (new_feature_story_points.nil? || new_feature_story_points.empty?)
          new_feature_story_points = ask("\nPlease enter the estimate points(0/1/2/3) for this feature story.\nIf you don't want to estimate then enter n")
      end
      while (!["0","1","2","3","n"].include?(new_feature_story_points.downcase))
          new_feature_story_points = ask("\nInvalid entry...Please enter the estimate points(0/1/2/3) for this feature story.\nIf you don't want to estimate then enter n")
      end
      if new_feature_story_points.downcase == "n"
          new_feature_story.estimate = -1
          else
          new_feature_story.estimate = new_feature_story_points
      end

      if args.any?{|arg| arg.include?("-tl")} && !(backlog_stories.empty? || backlog_stories.nil?)
          backlog_first_story = backlog_stories.first
          (new_feature_story.create).move(:before, backlog_first_story)
          elsif args.any?{|arg| arg.include?("-bl")} && !(backlog_stories.empty? || backlog_stories.nil?)
          backlog_last_story = backlog_stories.last
          (new_feature_story.create).move(:after, backlog_last_story)
          else
          backlog_first_story = backlog_stories.first
          (new_feature_story.create).move(:before, backlog_first_story)
      end
  end

  private

  def pwd
    command = OS.windows? ? 'echo %cd%': 'pwd'
    GitPivotalTrackerIntegration::Util::Shell.exec(command).chop
  end

end
