module Jiveapps::Command
  class Help < Base

    def index
      puts "jiveapps gem: v#{Jiveapps::VERSION}"
      puts <<-eos
=== Summary
The "jiveapps" program is a command line tool for building and hosting Jive App front-ends.

=== General Commands

help                                       # show this usage

list                                       # list your apps
create <app_name>                          # create a new app
info [--app <app_name>]                    # displays information about an app
install [--app <app_name>]                 # install an app on the sandbox (if you removed it, you can reinstall)

keys                                       # show your user's public keys
keys:add [<path to keyfile>]               # add a public key. optionally include path
keys:remove <keyname>                      # remove a key by name (user@host)

oauth                                      # show the oauth services for this app
oauth:add <service_name> <key> <secret>    # add an oauth service for this app
oauth:remove <service_name>                # remove an oauth service for this app

sharing                                    # list collaborators
sharing:add <username>                     # add a collaborator
sharing:remove <username>                  # remove a collaborator

=== Simple Workflow Example:

$ jiveapps create myapp                    # create a new app named "myapp"
$ cd myapp                                 # switch into app's directory

 ... develop your app ...

$ git add .                                # stage all files for commit
$ git commit -m "some updates to my app"   # commit to your local git repository
$ git push jiveapps master                 # push updates to jive
eos
    end

  end
end
