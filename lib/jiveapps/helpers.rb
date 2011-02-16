module Jiveapps
  module Helpers
    def home_directory
      running_on_windows? ? ENV['USERPROFILE'] : ENV['HOME']
    end

    def running_on_windows?
      RUBY_PLATFORM =~ /mswin32|mingw32/
    end

    def running_on_a_mac?
      RUBY_PLATFORM =~ /-darwin\d/
    end

    def display(msg, newline=true)
      if newline
        puts(msg)
      else
        print(msg)
        STDOUT.flush
      end
    end

    def error(msg)
      STDERR.puts(msg)
      exit 1
    end

    def confirm(message="Are you sure you wish to continue? (y/n)?")
      display("#{message} ", false)
      ask.downcase == 'y'
    end

    def confirm_command(app = app)
      if extract_option('--force')
        display("Warning: The --force switch is deprecated, and will be removed in a future release. Use --confirm #{app} instead.")
        return true
      end

      raise(Jiveapps::Command::CommandFailed, "No app specified.\nRun this command from app folder or set it adding --app <app name>") unless app

      confirmed_app = extract_option('--confirm', false)
      if confirmed_app
        unless confirmed_app == app
          raise(Jiveapps::Command::CommandFailed, "Confirmed app #{confirmed_app} did not match the selected app #{app}.")
        end
        return true
      else
        display "\n !    Potentially Destructive Action"
        display " !    To proceed, type \"#{app}\" or re-run this command with --confirm #{@app}"
        display "> ", false
        if ask.downcase != app
          display " !    Input did not match #{app}. Aborted."
          false
        else
          true
        end
      end
    end

    # Ask user for input, trim the response
    def ask
      gets.strip
    end

    # Display Oauth Service list
    # Example Output:
    # === 2 OAuth services for app-name
    # 1. "foo" Service
    #      Consumer Key:     bar
    #      Consumer Secret:  baz
    # 2. "foo2" Service
    #      Consumer Key:     bar
    #      Consumer Secret:  baz
    def display_oauth_services(oauth_services, app_name)
      if oauth_services.empty?
        display "No OAuth Services for #{app_name}"
      else
        display "=== #{oauth_services.size} OAuth Service#{'s' if oauth_services.size > 1} for #{app_name}"
        oauth_services.each_with_index do |oauth_service, index|
          display "#{index+1}. \"#{oauth_service['name']}\" Service\n     Consumer Key:     #{oauth_service['key']}\n     Consumer Secret:  #{oauth_service['secret']}"
        end
      end
    end

  end
end
