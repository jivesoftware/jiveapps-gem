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
          app["web_url"] = "http://#{Jiveapps::HOSTNAME}/apps/#{app['name']}/app.xml"
          app["git_url"] = "git://#{Jiveapps::HOSTNAME}/#{app['name']}.git"

          display "=== #{app['name']}"
          display "Web URL: #{app['web_url']}"
          display "Git URL: #{app['git_url']}"
        end
      end
    end

    def create
      require 'rubygems'
      require 'rubigen'

      require 'rubigen/scripts/generate'
      RubiGen::Base.use_application_sources!
      RubiGen::Scripts::Generate.new.run(@args, :generator => 'create')
    end

    def version
      puts Jiveapps::Client.version
    end

  end
end
