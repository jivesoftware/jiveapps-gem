module Jiveapps::Command
  class Oauth < Base

    # Lists OAuth Services registered for this app
    def list
      app_name = extract_app

      oauth_services = jiveapps.oauth_services(app_name)
      if oauth_services.empty?
        display "No oauth services for #{app_name}"
      else
        display "=== #{oauth_services.size} service#{'s' if oauth_services.size > 1} for #{app_name}"
        oauth_services.each_with_index do |oauth_service, index|
          display "  #{index+1}. #{format_key_for_display(oauth_service)}"
        end
      end
    end
    alias :index :list

    # Register a new OAuth Service for use with this app
    def add
      usage  = 'jiveapps oauth:add <servicename> <key> <secret>'
      app_name = extract_app
      raise CommandFailed, "Missing servicename. Usage:\n#{usage}" unless servicename = args.shift
      raise CommandFailed, "Missing key. Usage:\n#{usage}"         unless key         = args.shift
      raise CommandFailed, "Missing secret. Usage:\n#{usage}"      unless secret      = args.shift

      display "=== Registering a new OAuth Service: \"#{servicename}\""
      response = jiveapps.add_oauth_service(app_name, servicename, key, secret)
      Jiveapps::Command.run_internal('oauth:list', [])
    end

    # Remove an OAuth Service
    def remove
      usage  = 'jiveapps oauth:remove <servicename>'
      app_name = extract_app
      raise CommandFailed, "Missing servicename. Usage:\n#{usage}" unless servicename = args.shift

      if confirm "Are you sure you wish to remove the OAuth service \"#{servicename}\"? (y/n)?"
        display "=== Removing Oauth Service \"#{servicename}\""
        response = jiveapps.remove_oauth_service(app_name, servicename)
        Jiveapps::Command.run_internal('oauth:list', [])
      end
    end

      # Formats an Oauth Service for display
      # Example Output:
      # Service Name: "twitter", Key: "41873830eef3438893c04a6c2e2cfd86", Secret: "4BD1//Y+9Jdp0/B4zfG2BCoszDY="
      def format_key_for_display(oauth_service)
        "Name: \"#{oauth_service['name']}\", Key: \"#{oauth_service['key']}\", Secret: \"#{oauth_service['secret']}\""
      end

  end
end