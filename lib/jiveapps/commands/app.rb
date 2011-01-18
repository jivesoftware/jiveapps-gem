module Jiveapps::Command
  class App < Base

    attr_reader :current_app

    def version
      display Jiveapps::Client.gem_version_string
    end

    def list
      jiveapps_list = jiveapps.list
      return if jiveapps_list.nil?

      formatted_list = jiveapps_list.map do |app|
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
      name = (args.first && !args.first =~ /^\-\-/) ? args.first : extract_app
      app = jiveapps.info(name)
      if app == nil
        display "App not found."
      else
        display "=== #{app['name']}"
        display_app_info(app)
      end
    end

    def create
      debug "Running in debug mode."
      app_list = Jiveapps::Command.run_internal('auth:check', []) # check auth credentials and ssh key before generating app
      return unless app_list.class == Array
      Jiveapps::Command.run_internal('keys:add', [])
      display "Creating new Jive App \"#{app_name}\"..."
      create_remote_app
      generate_app
      create_local_git_repo_and_push_to_remote
      register_app
      create_notify_user
    end

    def install
      display "Installing \"#{app_name}\" on the Jive App Sandbox: ", false
      app = jiveapps.install(app_name)
      handle_response_errors
      if app == nil
        display "App not found."
      else
        display "=== #{app['name']}"
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
      display "Step 1 of 4. Check availability and create remote repository: ", false
      @current_app = jiveapps.create(app_name)
      handle_response_errors
    end

    def generate_app
      return unless current_app
      display "Step 2 of 4. Generate app scaffolding."

      require 'rubygems'
      require 'rubigen'
      require 'rubigen/scripts/generate'
      RubiGen::Base.use_application_sources!
      RubiGen::Scripts::Generate.new.run(@args, :generator => 'create')
    end

    def create_local_git_repo_and_push_to_remote
      return unless current_app
      display "Step 3 of 4. Creating local Git repository and push to remote: ", false

      Dir.chdir(File.join(Dir.pwd, app_name)) do

        run("git init")
        run("git add .")
        run('git commit -m "initial commit"')
        run("git remote add jiveapps #{current_app['git_url']}")
        run("git push jiveapps master")
      end

      if $? == 0
        display "SUCCESS"
      else
        display "FAILURE"
        display "Git Push failed. Deleting app and cleaning up. Check SSH key and try again:\n\n" +
                "$ jiveapps keys:list\n" +
                "$ jiveapps keys:remove <user@machine>\n" +
                "$ jiveapps keys:add\n" +
                "$ jiveapps create #{app_name}"
        delete_app
      end
    end

    def register_app
      return unless current_app
      display "Step 4 of 4. Registering app on the Jive Apps Dev Center and installing on sandbox: ", false

      @current_app = jiveapps.register(app_name)
      handle_response_errors
    end

    def delete_app
      run("rm -rf #{app_name}")
      jiveapps.delete_app(app_name)
      @current_app = nil # halt further actions
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

    def handle_response_errors
      if @current_app.class == Hash && @current_app["errors"]
        display "FAILURE"
        @current_app["errors"].each do |key, value|
          display "Error on \"#{key}\": #{value}"
        end
        @current_app = nil
      else
        display "SUCCESS"
      end
    end

  end
end
