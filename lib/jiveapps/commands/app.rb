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

    def clone
      usage "jiveapps clone <appname>"
      catch_args :appname

      app = jiveapps.info(@appname)
      if app == nil
        display "=== App not found."
      else
        # if dir already exists, output message and stop
        if File.exists?(@appname) && File.directory?(@appname)
          display "=== #{@appname} folder already exists."
        else
          display "=== Cloning #{@appname}..."
          run("git clone #{app['git_url']} --origin jiveapps", :exec => true)
        end
      end
    end

    def create
      usage    = "\n  Usage:\n  $ jiveapps create <appname>"
      catch_args :appname

      debug "Running in debug mode."
      check_git_version
      check_if_dir_already_exists
      app_list = Jiveapps::Command.run_internal('auth:check', []) # check auth credentials and ssh key before generating app
      return unless app_list.class == Array
      Jiveapps::Command.run_internal('keys:add', ["--silent"])
      display "=== Creating new Jive App \"#{@appname}\"..."
      create_remote_app
      generate_app
      create_local_git_repo_and_push_to_remote
      check_app_push
      register_app
      create_notify_user
    end

    def install
      name = (args.first && !args.first =~ /^\-\-/) ? args.first : extract_app
      display "=== Installing \"#{name}\" on the Jive App Sandbox: ", false
      app = jiveapps.install(name)
      handle_response_errors
      if app == nil
        display "App not found."
      else
        display "=== #{app['name']}"
        display_app_info(app)
      end
    end

    def delete
      name = (args.first && !args.first =~ /^\-\-/) ? args.first : extract_app
      app = jiveapps.info(name)
      if app == nil
        display "App not found."
      else
        display "Are you sure you want to delete the app \"#{name}\" [y/N]? ", false
        answer = gets.strip
        if answer == 'y'
          display "=== Deleting \"#{name}\": ", false
          @current_app = jiveapps.delete_app(name)
          handle_response_errors
        end
      end
    end

    private

    def create_remote_app
      display "Step 1 of 4. Checking availability and creating remote repository... ", false
      @current_app = jiveapps.create(@appname)
      handle_response_errors
    end

    def generate_app
      return unless current_app
      display "Step 2 of 4. Generating app scaffolding..."

      require 'rubygems'
      require 'rubigen'
      require 'rubigen/scripts/generate'
      RubiGen::Base.use_application_sources!
      RubiGen::Scripts::Generate.new.run([@appname], :generator => 'create')
    end

    def create_local_git_repo_and_push_to_remote
      return unless current_app
      display "Step 3 of 4. Creating local Git repository and pushing to remote... ", false

      result = nil
      Dir.chdir(File.join(Dir.pwd, @appname)) do
        result = run("git init")
        result = run("git add .")                                         unless result.error?
        result = run("git commit -m \"initial commit\"")                  unless result.error?
        result = run("git remote add jiveapps #{current_app['git_url']}") unless result.error?
        result = run("git push jiveapps master")                          unless result.error?
      end

      if result.error?
        display "FAILURE"
        display result.error
        display_git_push_fail_info
        delete_app_and_dir
      else
        display "SUCCESS"
        Dir.chdir(File.join(Dir.pwd, @appname)) do
          run("git branch --set-upstream master jiveapps/master")
        end
      end
    end

    def check_app_push
      return unless current_app
      response_code = get_response_code(current_app['app_url'])
      if response_code != 200
        display_git_push_fail_info
        delete_app_and_dir
      end
    end

    def register_app
      return unless current_app
      display "Step 4 of 4. Registering app on the Jive Apps Dev Center and installing on sandbox... ", false

      @current_app = jiveapps.register(@appname)
      handle_response_errors
    end

    def delete_app_and_dir
      run("rm -rf #{@appname}")
      jiveapps.delete_app(@appname)
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
      if app['oauth_services'] && app['oauth_services'].length > 0
        oauth_services = app['oauth_services'].map{ |o| o['oauth_service'] }
        display_oauth_services(oauth_services, app['name'])
      end
    end

    def display_git_push_fail_info
      display "Git Push failed. Deleting app and cleaning up. Check SSH key and try again:\n\n" +
              "$ jiveapps keys:list\n" +
              "$ jiveapps keys:remove <user@machine>\n" +
              "$ jiveapps keys:add\n" +
              "$ jiveapps create #{@appname}"
    end

    def handle_response_errors
      if @current_app.class == Hash && @current_app["errors"]
        display "FAILURE"
        @current_app["errors"].each do |key, value|
          if key == 'base'
            display "Error: #{value}"
          else
            display "Error on \"#{key}\": #{value}"
          end
        end
        @current_app = nil
      else
        display "SUCCESS"
      end
    end

    def get_response_code(url)
      begin
        RestClient.get(url).code
      rescue => e
        e.respond_to?(:response) ? e.response.code : -1
      end
    end

    def check_if_dir_already_exists
      if File.directory?(@appname)
        error("A directory named \"#{@appname}\" already exists. Please delete or move directory and try again.")
      end
    end

  end
end
