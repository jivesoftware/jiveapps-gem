module Jiveapps::Command
  class Oauth < Base

    # Lists OAuth Services registered for this app
    def list
      app_name = extract_app

      oauth_services = jiveapps.oauth_services(app_name)
      display_oauth_services(oauth_services, app_name)
    end
    alias :index :list

    # Register a new OAuth Service for use with this app
    def add
      usage    = "\n  Usage:\n  $ jiveapps oauth:add <servicename> <key> <secret>"
      app_name = extract_app
      raise CommandFailed, "Missing 3 parameters: <servicename>, <key>, and <secret>#{usage}" unless servicename = args.shift
      raise CommandFailed, "Missing 2 parameters: <key> and <secret>#{usage}"                 unless key         = args.shift
      raise CommandFailed, "Missing 1 parameter: <secret>#{usage}"                            unless secret      = args.shift

      display "=== Registering a new OAuth Service: \"#{servicename}\""
      response = jiveapps.add_oauth_service(app_name, servicename, key, secret)
      Jiveapps::Command.run_internal('oauth:list', [])
    end

    # Remove an OAuth Service
    def remove
      usage    = "\n  Usage:\n  $ jiveapps oauth:remove <servicename>"
      app_name = extract_app
      raise CommandFailed, "Missing 1 parameter: <servicename>#{usage}" unless servicename = args.shift

      if confirm "Are you sure you wish to remove the OAuth service \"#{servicename}\"? (y/n)?"
        display "=== Removing Oauth Service \"#{servicename}\""
        response = jiveapps.remove_oauth_service(app_name, servicename)
        Jiveapps::Command.run_internal('oauth:list', [])
      end
    end

  end

end
