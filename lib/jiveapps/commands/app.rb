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
          display "Git URL: #{app['git_url']}"
          display "App URL: #{app['app_url']}"
        end
      end
    end

    def create
      # check auth credentials and ssh key before generating app
      Jiveapps::Command.run_internal('auth:check', [])
      create_remote_app
      generate_app
      create_local_git_repo_and_push_to_remote
      create_notify_user
    end

    def version
      puts Jiveapps::Client.version
    end

    private

    def create_remote_app
      @current_app = jiveapps.create(app_name)
    end

    def generate_app
      require 'rubygems'
      require 'rubigen'
      require 'rubigen/scripts/generate'
      RubiGen::Base.use_application_sources!
      RubiGen::Scripts::Generate.new.run(@args, :generator => 'create')
    end

    def create_local_git_repo_and_push_to_remote
      run("git init #{app_name}")
      run("cd #{app_name} && git add . && git commit -q -m 'initial commit'")
      run("cd #{app_name} && git remote add jiveapps #{current_app['git_url']}")
      run("cd #{app_name} && git push -q jiveapps master")
    end

    def create_notify_user
      display ""
      display ""
      display ""
      display "Congratulations, you have created a new Jive App!"
      display "================================================="
      display "Git URL: #{current_app['git_url']}"
      display "App URL: #{current_app['app_url']}"
    end

    def app_name
      args.first
    end

    def run(command)
      # puts "DEBUG: $ #{command}"
      `#{command} > /dev/null`
    end

  end
end
