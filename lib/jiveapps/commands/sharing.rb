module Jiveapps::Command
  class Sharing < BaseWithApp
    def list
      display_collaborators
    end
    alias :index :list

    def add
      usage "jiveapps sharing:add <username>"
      catch_args :username

      display "=== Adding commit access to #{app} for \"#{@username}\""
      jiveapps.add_collaborator(app, @username)
      display_collaborators
    end

    def remove
      usage "jiveapps sharing:remove <username>"
      catch_args :username

      return unless confirm("Are you sure you wish to remove commit access to #{app} for \"#{@username}\"? (y/n)?")
      display "=== Removing commit access to #{app} for \"#{@username}\""
      jiveapps.remove_collaborator(app, @username)
      display_collaborators
    end

    def display_collaborators
      collaborators = jiveapps.list_collaborators(app)
      display "=== #{collaborators.length} #{collaborators.length == 1 ? 'user has' : 'users have'} commit access to #{app}"
      collaborators.each_with_index do |collaborator, index|
        display "#{index+1}. #{collaborator[:username]}"
      end
    end
  end
end