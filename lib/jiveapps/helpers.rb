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

    def ask
      gets.strip
    end

  end
end
