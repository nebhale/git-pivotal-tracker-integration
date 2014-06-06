#! /usr/bin/env rvm ruby-1.9.3-head do ruby
# encoding: utf-8

require 'rubygems'
require 'logger'
require 'faraday'
require 'json'

require 'awesome_print' # for debug output

class Toggl
  attr_accessor :conn, :debug

  def initialize(username=nil, password='api_token', debug=nil)
    self.debug_on(debug) if !debug.nil?
    if (password.to_s == 'api_token' && username.to_s == '')
      toggl_api_file = ENV['HOME']+'/.toggl'
      if FileTest.exist?(toggl_api_file) then
        username = IO.read(toggl_api_file)
      else
        raise SystemCallError, "Expecting api_token in file ~/.toggl or parameters (api_token) or (username, password)"
      end
    end

    @conn = connection(username, password)
  end

  def connection(username, password)
    Faraday.new(url: 'https://www.toggl.com/api/v8') do |faraday|
      faraday.request :url_encoded
      faraday.response :logger, Logger.new('faraday.log')
      faraday.adapter Faraday.default_adapter
      faraday.headers = {"Content-Type" => "application/json"}
      faraday.basic_auth username, password
    end
  end

  def debug_on(debug=true)
    puts "debugging is %s" % [debug ? "ON" : "OFF"]
    @debug = debug
  end

  def checkParams(params, fields=[])
    raise ArgumentError, 'params is not a Hash' unless params.is_a? Hash
    return if fields.empty?
    errors = []
    for f in fields
      errors.push("params[#{f}] is required") unless params.has_key?(f)
    end
    raise ArgumentError, errors.join(', ') if !errors.empty?
  end

#----------#
#--- Me ---#
#----------#

  def me(all=nil)
    # TODO: Reconcile this with get_client_projects
    res = get "me%s" % [all.nil? ? "" : "?with_related_data=#{all}"]
  end

  def my_clients(user)
    user['projects']
  end

  def my_projects(user)
    user['projects']
  end

  def my_tags(user)
    user['tags']
  end

  def my_time_entries(user)
    user['time_entries']
  end

  def my_workspaces(user)
    user['workspaces']
  end

#---------------#
#--- Clients ---#
#---------------#

# name  : The name of the client (string, required, unique in workspace)
# wid   : workspace ID, where the client will be used (integer, required)
# notes : Notes for the client (string, not required)
# hrate : The hourly rate for this client (float, not required, available only for pro workspaces)
# cur   : The name of the client's currency (string, not required, available only for pro workspaces)
# at    : timestamp that is sent in the response, indicates the time client was last updated

  def create_client(params)
    checkParams(params, [:name, :wid])
    post "clients", {client: params}
  end

  def get_client(client_id)
    get "clients/#{client_id}"
  end

  def update_client(client_id, params)
    put "clients/#{client_id}", {client: params}
  end

  def delete_client(client_id)
    delete "clients/#{client_id}"
  end

  def get_client_projects(client_id, params={})
    active = params.has_key?(:active) ? "?active=#{params[:active]}" : ""
    get "clients/#{client_id}/projects#{active}"
  end


#----------------#
#--- Projects ---#
#----------------#

# name        : The name of the project (string, required, unique for client and workspace)
# wid         : workspace ID, where the project will be saved (integer, required)
# cid         : client ID(integer, not required)
# active      : whether the project is archived or not (boolean, by default true)
# is_private  : whether project is accessible for only project users or for all workspace users (boolean, default true)
# template    : whether the project can be used as a template (boolean, not required)
# template_id : id of the template project used on current project's creation
# billable    : whether the project is billable or not (boolean, default true, available only for pro workspaces)
# at          : timestamp that is sent in the response for PUT, indicates the time task was last updated
# -- Undocumented --
# color       : number (in the range 0-23?)

  def create_project(params)
    checkParams(params, [:name, :wid])
    post "projects", {project: params}
  end

  def get_project(project_id)
    get "projects/#{project_id}"
  end

  def update_project(project_id, params)
    put "projects/#{project_id}", {project: params}
  end

  def get_project_users(project_id)
    get "projects/#{project_id}/project_users"
  end

#---------------------#
#--- Project users ---#
#---------------------#

# pid      : project ID (integer, required)
# uid      : user ID, who is added to the project (integer, required)
# wid      : workspace ID, where the project belongs to (integer, not-required, project's workspace id is used)
# manager  : admin rights for this project (boolean, default false)
# rate     : hourly rate for the project user (float, not-required, only for pro workspaces) in the currency of the project's client or in workspace default currency.
# at       : timestamp that is sent in the response, indicates when the project user was last updated
# -- Additional fields --
# fullname : full name of the user, who is added to the project

  def create_project_user(params)
    checkParams(params, [:pid, :uid])
    params[:fields] = "fullname"  # for simplicity, always request fullname field
    post "project_users", {project_user: params}
  end

  def update_project_user(project_user_id, params)
    params[:fields] = "fullname"  # for simplicity, always request fullname field
    put "project_users/#{project_user_id}", {project_user: params}
  end

  def delete_project_user(project_user_id)
    delete "project_users/#{project_user_id}"
  end

#------------#
#--- Tags ---#
#------------#

# name : The name of the tag (string, required, unique in workspace)
# wid  : workspace ID, where the tag will be used (integer, required)

  def create_tag(params)
    checkParams(params, [:name, :wid])
    post "tags", {tag: params}
  end

  # ex: update_tag(12345, {name: "same tame game"})
  def update_tag(tag_id, params)
    put "tags/#{tag_id}", {tag: params}
  end

  def delete_tag(tag_id)
    delete "tags/#{tag_id}"
  end

#-------------#
#--- Tasks ---#
#-------------#

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

  def create_task(params)
    checkParams(params, [:name, :pid])
    post "tasks", {task: params}
  end

  def get_task(task_id)
    get "tasks/#{task_id}"
  end

  # ex: update_task(1894675, {active: true, estimated_seconds: 4500, fields: "done_seconds,uname"})
  def update_task(*task_id, params)
    put "tasks/#{task_id.join(',')}", {task: params}
  end

  def delete_task(*task_id)
    delete "tasks/#{task_id.join(',')}"
  end

#--------------------#
#--- Time entries ---#
#--------------------#

# description  : (string, required)
# wid          : workspace ID (integer, required if pid or tid not supplied)
# pid          : project ID (integer, not required)
# tid          : task ID (integer, not required)
# billable     : (boolean, not required, default false, available for pro workspaces)
# start        : time entry start time (string, required, ISO 8601 date and time)
# stop         : time entry stop time (string, not required, ISO 8601 date and time)
# duration     : time entry duration in seconds. If the time entry is currently running, the duration attribute contains a negative value, denoting the start of the time entry in seconds since epoch (Jan 1 1970). The correct duration can be calculated as current_time + duration, where current_time is the current time in seconds since epoch. (integer, required)
# created_with : the name of your client app (string, required)
# tags         : a list of tag names (array of strings, not required)
# duronly      : should Toggl show the start and stop time of this time entry? (boolean, not required)
# at           : timestamp that is sent in the response, indicates the time item was last updated

  def create_time_entry(params)
    checkParams(params, [:description, :start, :created_with])
    if !params.has_key?(:wid) and !params.has_key?(:pid) and !params.has_key?(:tid) then
      raise ArgumentError, "one of params['wid'], params['pid'], params['tid'] is required"
    end
    post "time_entries", {time_entry: params}
  end

  def start_time_entry(params)
    if !params.has_key?(:wid) and !params.has_key?(:pid) and !params.has_key?(:tid) then
      raise ArgumentError, "one of params['wid'], params['pid'], params['tid'] is required"
    end
    post "time_entries/start", {time_entry: params}
  end

  def stop_time_entry(time_entry_id)
    put "time_entries/#{time_entry_id}/stop", {}
  end

  def get_time_entry(time_entry_id)
    get "time_entries/#{time_entry_id}"
  end

  def update_time_entry(time_entry_id, params)
    put "time_entries/#{time_entry_id}", {time_entry: params}
  end

  def delete_time_entry(time_entry_id)
    delete "time_entries/#{time_entry_id}"
  end

  def iso8601(date)
    return nil if date.nil?
    if date.is_a?(Time) or date.is_a?(Date)
      iso = date.iso8601
    elsif date.is_a?(String)
      iso =  DateTime.parse(date).iso8601
    else
      raise ArgumentError, "Can't convert #{date.class} to ISO-8601 Date/Time"
    end
    return Faraday::Utils.escape(iso)
  end

  def get_time_entries(start_date=nil, end_date=nil)
    params = []
    params.push("start_date=#{iso8601(start_date)}") if !start_date.nil?
    params.push("end_date=#{iso8601(end_date)}") if !end_date.nil?
    get "time_entries%s" % [params.empty? ? "" : "?#{params.join('&')}"]
  end

#-------------#
#--- Users ---#
#-------------#

# api_token                 : (string)
# default_wid               : default workspace id (integer)
# email                     : (string)
# jquery_timeofday_format   : (string)
# jquery_date_format        :(string)
# timeofday_format          : (string)
# date_format               : (string)
# store_start_and_stop_time : whether start and stop time are saved on time entry (boolean)
# beginning_of_week         : (integer, Sunday=0)
# language                  : user's language (string)
# image_url                 : url with the user's profile picture(string)
# sidebar_piechart          : should a piechart be shown on the sidebar (boolean)
# at                        : timestamp of last changes
# new_blog_post             : an object with toggl blog post title and link

#------------------#
#--- Workspaces ---#
#------------------#

# name    : (string, required)
# premium : If it's a pro workspace or not. Shows if someone is paying for the workspace or not (boolean, not required)
# at      : timestamp that is sent in the response, indicates the time item was last updated

  def workspaces
    get "workspaces"
  end

  def clients(workspace=nil)
    if workspace.nil?
      get "clients"
    else
      get "workspaces/#{workspace}/clients"
    end
  end

  def projects(workspace, params={})
    active = params.has_key?(:active) ? "?active=#{params[:active]}" : ""
    get "workspaces/#{workspace}/projects#{active}"
  end

  def users(workspace)
    get "workspaces/#{workspace}/users"
  end

  def tasks(workspace, params={})
    active = params.has_key?(:active) ? "?active=#{params[:active]}" : ""
    get "workspaces/#{workspace}/tasks#{active}"
  end

#---------------#
#--- Private ---#
#---------------#

  private

  def get(resource)
    puts "GET #{resource}" if @debug
    full_res = self.conn.get(resource)
    # ap full_res.env if @debug
    res = JSON.parse(full_res.env[:body])
    res.is_a?(Array) || res['data'].nil? ? res : res['data']
  end

  def post(resource, data)
    puts "POST #{resource} / #{data}" if @debug
    full_res = self.conn.post(resource, JSON.generate(data))
    ap full_res.env if @debug
    if (200 == full_res.env[:status]) then
      res = JSON.parse(full_res.env[:body])
      res['data'].nil? ? res : res['data']
    else
      eval(full_res.env[:body])
    end
  end

  def put(resource, data)
    puts "PUT #{resource} / #{data}" if @debug
    full_res = self.conn.put(resource, JSON.generate(data))
    # ap full_res.env if @debug
    res = JSON.parse(full_res.env[:body])
    res['data'].nil? ? res : res['data']
  end

  def delete(resource)
    puts "DELETE #{resource}" if @debug
    full_res = self.conn.delete(resource)
    # ap full_res.env if @debug
    (200 == full_res.env[:status]) ? "" : eval(full_res.env[:body])
  end

end