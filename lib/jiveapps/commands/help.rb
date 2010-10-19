module Jiveapps::Command
  class Help < Base

    def index
      puts <<-eos
=== General Commands

help                         # show this usage

create <name>                # create a new app

=== Example:

 jiveapps create myapp                     # create a new app named "myapp"
 cd myapp                                  # switch into app's directory

 ... develop app

 git add .                                 # stage all files for commit
 git commit -m "some updates to my app"    # commit to your local git repository
 git push jiveapps master                  # push updates to jive
       eos
    end
  end
end
