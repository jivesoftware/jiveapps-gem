require 'directory_watcher'
module Jiveapps::Command
  class Livedev < BaseWithApp

    def on
      info = jiveapps.info(app)
      if info == nil
        display "App not found."
      else
        # Check if LiveDev is already running...
        if File.exist?(".git/livedev")
          return unless confirm "LiveDev appears to already be running in another window.\nIf so, you should not run it twice, or strange things could happen.\nAre you sure you wish to continue? (y/n)?"
        else
          # Create livedev run file so above check can happen if command is run in two separate terminals
          File.open(".git/livedev", 'w') {|f| f.write("") }
        end

        display "=== Starting LiveDev: #{app}"

        display "1/4: Checking out LiveDev branch #{branch_name}."

        # check if livedev branch exists...
        if Kernel.system("git show-ref --quiet --verify refs/heads/#{branch_name}")
          # if it does, switch to it
          run("git checkout #{branch_name}")
        else
          # if it doesn't, create it and switch to it, and do an initial push
          run("git checkout -b #{branch_name}")
        end

        # sync remote livedev branch with local - force update to match local
        display "2/4: Syncing local branch with remote server."
        run("git push -f jiveapps #{branch_name}")

        # switch server to run in livedev mode
        display "3/4: Switching the Jive App Sandbox to point to LiveDev branch."
        jiveapps.livedev(app, 'on')

        display "4/4: Watching directory for changes. Leave this process running"
        display "     until you wish to quit LiveDev. Hit CTRL-C to quit."
        display "     To view your app while in LiveDev mode, go to:"
        display "     #{info['sandbox_canvas_url']}"
        display "================================================================"
        watch_dir_and_commit_changes
      end
    end
    alias :index :on

    def off
      display "\n\n\n=== Stopping LiveDev: #{app}"

      # remove livedev run file if it exists
      if File.exist?(".git/livedev")
        File.delete(".git/livedev")
      end

      # switch server to run in normal mode
      display "1/3: Switching the Jive App Sandbox to point to master branch."
      jiveapps.livedev(app, 'off')

      display "2/3: Checking out master branch."
      run("git checkout master")
      run("git pull jiveapps master")

      if `git diff #{branch_name} master`.length > 0
        display "3/3: Merging changes from LiveDev branch without committing."
        run("git merge #{branch_name} --squash")

        display "\n\n\n=== You can now review your changes, then keep or forget them:"
        display " 1. Review your changes:"
        display "    $ git status"
        display "    $ git diff --cached"
        display ""
        display " 2. Commit them to the master branch:"
        display "    $ git commit -m 'your commit message here'"
        display "    $ git push jiveapps master"
        display "    $ git branch -D #{branch_name}"
        display ""
        display " 3. Or forget them:"
        display "    $ git reset --hard HEAD"
        display "    $ git branch -D #{branch_name}"
      else
        display "=== No changes exist in the LiveDev branch. Now running in standard dev mode."
      end
    end

    private

      def branch_name
        "livedev/#{jiveapps.user}"
      end

      def watch_dir_and_commit_changes
        @dw = DirectoryWatcher.new '.', :glob => '**/*', :pre_load => true
        @dw.interval = 1
        @dw.add_observer do |*args| 
          args.each do |event| 
            if event.type == :added || event.type == :modified
              run("git add #{event.path}")
            elsif event.type == :removed
              run("git rm #{event.path}")
            end
            display "  - [#{Time.now.strftime("%Y-%m-%d %T")}] LiveDev: #{event.type} #{event.path}"
            run("git commit -m \"LiveDev: #{event.type} '#{event.path}'\"")
            run("git push -f jiveapps #{branch_name}")
          end
        end

        @dw.start

        while true do
          # print "."
          begin
            gets
          rescue Interrupt # Catch CTRL-C and display warning.
            display_warning
          end
        end

        # gets # when the user hits "enter" the script will terminate
      end

      def display_warning
        puts ""
        puts "Would you like to quit LiveDev mode now? y/n? "
        begin
          answer = gets.strip
        rescue Interrupt
        end
        if answer == 'y'
          @dw.stop
          off
          exit
        else
          display "Resuming..."
          return
        end
      end

  end

end
