module Jiveapps::Command
  class Oauth < BaseWithApp

    # Lists OAuth Services registered for this app
    def list
      oauth_services = jiveapps.list_oauth_services(app)
      display_oauth_services(oauth_services, app)
    end
    alias :index :list

    # Register a new OAuth Service for use with this app
    def add
      usage "jiveapps oauth:add <servicename> <key> <secret>"
      catch_args :servicename, :key, :secret

      display "=== Registering a new OAuth Service: \"#{@servicename}\""
      response = jiveapps.add_oauth_service(app, @servicename, @key, @secret)
      list
    end

    # Remove an OAuth Service
    def remove
      usage "jiveapps oauth:remove <servicename>"
      catch_args :servicename

      return unless confirm "Are you sure you wish to remove the OAuth service \"#{@servicename}\"? (y/n)?"
      display "=== Removing Oauth Service \"#{@servicename}\""
      response = jiveapps.remove_oauth_service(app, @servicename)
      list
    end

  end

end
