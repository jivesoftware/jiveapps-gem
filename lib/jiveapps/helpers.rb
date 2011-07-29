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

    def usage(text)
      @usage = "\n  Usage:\n  $ #{text}"
    end

    def catch_args(*list)
      while current_arg = args.shift
        instance_variable_set "@#{list.shift}", current_arg
      end
      raise Jiveapps::Command::CommandFailed, "Missing #{list.length} parameter#{list.length > 1 ? 's' : ''}: #{list.map{|l| '<' + l.to_s + '>'}.join(' ')}#{@usage}" if list.length > 0
    end

    def run(command, options={})
      options[:exec] ||= false

      puts "DEBUG: $ #{command}" if debug_mode?

      if options[:exec] == true
        exec command
      else
        sh(command)
      end
    end

    def sh(command)
      Shell.new(command).run
    end

    def debug_mode?
      return @debug_mode if @debug_mode.nil? == false

      if args.include?('--debug')
        args.delete('--debug')
        @debug_mode = true
      else
        @debug_mode = false
      end
    end

    def debug(msg)
      if debug_mode?
        puts "DEBUG: #{msg}"
      end
    end

    def has_program?(program)
      ENV['PATH'].split(File::PATH_SEPARATOR).any? do |directory|
        path = File.join(directory, program.to_s)
        if running_on_windows?
          File.exists?("#{path}.cmd") || File.exists?("#{path}.exe")
        else
          File.executable?(path)
        end
      end
    end

    def user_git_version
      return @git_version if @git_version
      error("Git not found. Please install Git 1.7 or higher. http://git-scm.com/download") unless has_program?("git")
      version_string = `git --version`.split(/\s+/).last
      @git_version = Gem::Version.new(version_string)
    end

    def check_git_version
      minimum_git_version = Gem::Version.new("1.7")
      if user_git_version < minimum_git_version
        error("Running Git version #{user_git_version}. Please install Git #{minimum_git_version} or higher. http://git-scm.com/download")
      end
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

    # Checks for existance of a git property. If it exists, return it.
    # If it doesn't, prompt for it, set it, and return it.
    #
    # Example:
    #   get_or_set_git_prop("--global user.name", "Author Name")
    #
    def get_or_set_git_prop(prop, title)
      val = `git config #{prop}`.to_s.strip
      while val.blank?
        display "Enter #{title}: ", false
        val = gets.strip
        if val.blank?
          display "#{title} cannot be blank."
        else
          `git config #{prop} "#{val}"`
        end
      end
      val
    end

    # Prompt for an app property. If user enters a value, return it, otherwise return the default
    #
    # Example:
    #   get_app_prop_with_default("App Name", "foobarbaz")
    #
    # Example Output:
    #   Enter App Name or hit enter for default [foobarbaz]:
    #
    def get_app_prop_with_default(title, default="")
      display "  Enter #{title} or hit enter for default [#{default}]: ", false
      val = gets.strip
      val.blank? ? default : val
    end

  end
end
