module Jiveapps::Command
  class App < Base

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
      name = args.first
      if name == nil
        display "No app specified."
        display "Run this command from app folder or set it by running: jiveapps info <app name>"
      else
        app = jiveapps.info(name)
        if app == nil
          display "App not found."
        else
          app["web_url"] = "http://#{Jiveapps::WEBHOST}/apps/#{app['name']}/app.xml"
          app["git_url"] = "git@#{Jiveapps::GITHOST}:#{app['name']}.git"

          display "=== #{app['name']}"
          display "Web URL: #{app['web_url']}"
          display "Git URL: #{app['git_url']}"
        end
      end
    end

    def create
      generate_app
      create_local_repo
      create_remote_git_repo_and_push
      create_notify_user
    end

    def version
      puts Jiveapps::Client.version
    end

    private

    def generate_app
      require 'rubygems'
      require 'rubigen'
      require 'rubigen/scripts/generate'
      RubiGen::Base.use_application_sources!
      RubiGen::Scripts::Generate.new.run(@args, :generator => 'create')
    end

    def create_local_repo
      run("git init #{app_name}")
      run("cd #{app_name} && git add . && git commit -q -m 'initial commit'")
    end

    def create_remote_git_repo_and_push
      jiveapps.create(app_name)
      run("cd #{app_name} && git remote add jiveapps git@#{Jiveapps::GITHOST}:#{app_name}.git")
      run("cd #{app_name} && git push -q jiveapps master")
    end

    def create_notify_user
      display ""
      display ""
      display ""
      display "Congratulations, you have created a new Jive App!"
      display "================================================="
      display "Git URL: git@#{Jiveapps::GITHOST}:#{app_name}.git"
      display "App URL: http://#{Jiveapps::WEBHOST}/apps/#{app_name}/app.xml"
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
