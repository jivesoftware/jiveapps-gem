module Jiveapps::Command
  class Sharing < BaseWithApp
    def list
      list = jiveapps.list_collaborators(app)
      display list.map { |c| c[:username] }.join("\n")
    end
    alias :index :list

    def add
      username = args.shift.downcase rescue ''
      raise(CommandFailed, "Specify a username to share the app with.") if username == ''
      display jiveapps.add_collaborator(app, username)
    end

    def remove
      username = args.shift.downcase rescue ''
      raise(CommandFailed, "Specify a username to remove from the app.") if username == ''
      jiveapps.remove_collaborator(app, username)
      display "Collaborator removed."
    end

    # def transfer
    #   username = args.shift.downcase rescue ''
    #   raise(CommandFailed, "Specify the email address of the new owner") if username == ''
    #   jiveapps.update(app, :transfer_owner => username)
    #   display "App ownership transfered. New owner is #{username}"
    # end
  end
end