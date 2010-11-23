module Jiveapps::Command
  class App < Base

    attr_reader :current_app

    def list
      formatted_list = jiveapps.list.map do |app|
        "  - " + app['name']
      end

      if formatted_list.size > 0
        display "Your apps:"
        display formatted_list
      else
        display "You have no apps."
      end
    end

    def info
      if app_name == nil
        display "No app specified."
        display "Run this command from app folder or set it by running: jiveapps info <app name>"
      else
        app = jiveapps.info(app_name)
        if app == nil
          display "App not found."
        else
          display "=== #{app['name']}"
          display_app_info(app)
        end
      end
    end

    def create
      # check auth credentials and ssh key before generating app
      Jiveapps::Command.run_internal('auth:check', [])
      create_remote_app
      generate_app
      create_local_git_repo_and_push_to_remote
      register_app
      create_notify_user
    end

    def install
      app = jiveapps.install(app_name)
      if app == nil
        display "App not found."
      else
        display "=== #{app['name']} - Installed"
        display_app_info(app)
      end
    end

    private

    def debug_mode?
      return @debug_mode if @debug_mode.nil? == false

      if args.include?('--debug')
        args.delete('--debug')
        @debug_mode = true
      else
        @debug_mode = false
      end
    end

    def create_remote_app
      debug "Creating remote app."
      @current_app = jiveapps.create(app_name)
      if @current_app.class == Hash && @current_app["errors"]
        if @current_app["errors"]["name"]
          display "Error: Name #{@current_app["errors"]["name"]}"
        end
        @current_app = nil
      end
    end

    def generate_app
      return unless current_app
      debug "Generating local app."

      require 'rubygems'
      require 'rubigen'
      require 'rubigen/scripts/generate'
      RubiGen::Base.use_application_sources!
      RubiGen::Scripts::Generate.new.run(@args, :generator => 'create')
    end

    def create_local_git_repo_and_push_to_remote
      return unless current_app
      debug "Creating local git repo and pushing to remote."

      Dir.chdir(File.join(Dir.pwd, app_name)) do

        run("git init")
        run("git add .")
        run('git commit -m "initial commit"')
        run("git remote add jiveapps #{current_app['git_url']}")
        run("git push jiveapps master")
      end
    end

    def register_app
      return unless current_app
      debug "Registering app."

      @current_app = jiveapps.register(app_name)
    end

    def create_notify_user
      return unless current_app
      debug "Notifying user."

      display ""
      display ""
      display ""
      display "Congratulations, you have created a new Jive App!"
      display "================================================="
      display_app_info(current_app)
    end

    def display_app_info(app)
      display "Git URL:               #{app['git_url']}"
      display "App URL:               #{app['app_url']}"
      display "Sandbox Canvas URL:    #{app['sandbox_canvas_url']}"
      display "Sandbox Dashboard URL: #{app['sandbox_dashboard_url']}"
      display "OAuth Consumer Key:    #{app['oauth_consumer_key']}"
      display "OAuth Consumer Secret: #{app['oauth_consumer_secret']}"
    end
    
    def app_name
      args.first
    end

    def run(command)
      if debug_mode?
        puts "DEBUG: $ #{command}"
        `#{command}`
      elsif running_on_windows?
        `#{command}` # TODO: figure out how to silence on Windows
      else
        `#{command} > /dev/null 2>&1` # silent
      end
    end

    def debug(msg)
      if debug_mode?
        puts "DEBUG: #{msg}"
      end
    end

  end
end
