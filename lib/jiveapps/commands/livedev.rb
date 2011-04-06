require 'directory_watcher'
module Jiveapps::Command
  class Livedev < BaseWithApp

    def on
      info = jiveapps.info(app)
      if info == nil
        display "App not found."
      else
        check_for_jiveapps_remote(info)

        # Check if LiveDev is already running...
        if File.exist?(".git/livedev")
          return unless confirm "LiveDev appears to already be running in another window.\nIf so, you should not run it twice, or strange things could happen.\nType \"y\" to continue anyway, or anything else to quit (recommended): (y/N)?"
        else
          # Create livedev run file so above check can happen
          # if command is run in two separate terminals
          File.open(".git/livedev", 'w') {|f| f.write("") }
        end

        display "=== Starting LiveDev: #{app}"

        display "1/4: Checking out LiveDev branch #{livedev_branch_name}."

        ask_to_recreate_branch_if_livedev_exists
        checkout_livedev_branch

        # sync remote livedev branch with local - force update to match local
        display "2/4: Syncing local branch with remote server."
        run("git push -f jiveapps #{livedev_branch_name}")

        # switch server to run in livedev mode
        display "3/4: Switching the Jive App Sandbox to point to LiveDev branch."
        jiveapps.livedev(app, 'on')

        display "4/4: Watching directory for changes. Leave this process running"
        display "     until you wish to quit LiveDev. Type \"exit\" to quit."
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

      display "2/3: Checking out master branch and pulling any remote changes."
      run("git checkout master")
      run("git pull jiveapps master")

      if `git diff #{livedev_branch_name} master`.length > 0
        display "3/3: Merging changes from LiveDev branch without committing."
        result = `git merge #{livedev_branch_name} --squash`

        # Check if a merge conflict occurred and display git message if so
        if result =~ /CONFLICT/
          puts "\n\n=== Merge conflicts occured:"
          puts result
        end

        display "\n\n\n=== You can now review your changes, then keep or forget them:"
        display " 1. Review your changes:"
        display "    $ git status"
        display "    $ git diff --cached  # review changes staged for commit"
        display "    $ git diff           # review conflicts" if result =~ /CONFLICT/
        display ""

        if result =~ /CONFLICT/
          display "        ... edit and fix conflicts ..."
          display ""
        end

        display " 2. Commit them to the master branch:"
        display "    $ git add <fixed-conflict-file-names>" if result =~ /CONFLICT/
        display "    $ git commit -m 'your commit message here'"
        display "    $ git push jiveapps master"
        display "    $ git branch -D #{livedev_branch_name}"
        display ""
        display " 3. Or forget them:"
        display "    $ git reset --hard HEAD"
        display "    $ git branch -D #{livedev_branch_name}"
      else
        display "=== No changes exist in the LiveDev branch. Now running in standard dev mode."
        run("git branch -d #{livedev_branch_name}") # deleting livedev branch since no changes exist
      end
    end

    private

      def livedev_branch_name
        "livedev/#{jiveapps.user}"
      end

      def current_branch_name
        `git symbolic-ref HEAD`.strip.gsub(/refs\/heads\//, '')
      end

      def ask_to_recreate_branch_if_livedev_exists
        if branch_exists?(livedev_branch_name)
          display "LiveDev branch already exists! You can either:"

          answer = ""
          while answer != "1" && answer != "2"
            display "     1. Delete and recreate branch from master"
            display "     2. Continue using existing LiveDev branch"
            display "     Select 1 or 2: ", false
            answer = gets.strip
            display "#{answer} is not a valid choice!" if answer != "1" && answer != "2"
          end

          # if user answers "1", delete the livedev branch. it will get re-created when it is checked out
          if answer == "1"
            run("git checkout master")
            run("git branch -D #{livedev_branch_name}")
          end

        end
      end

      def checkout_livedev_branch
        # check if livedev branch exists...
        if Kernel.system("git show-ref --quiet --verify refs/heads/#{livedev_branch_name}")
          # if it does, switch to it
          run("git checkout #{livedev_branch_name}")
        else
          # if it doesn't, create it and switch to it, and do an initial push
          run("git checkout -b #{livedev_branch_name}")
        end
      end

      def verify_livedev_branch
        if current_branch_name != livedev_branch_name
          checkout_livedev_branch
        end
      end

      def branch_exists?(branch)
        branches = `git branch`
        regex = Regexp.new('[\\n\\s\\*]+' + Regexp.escape(branch.to_s) + '\\n')
        result = ((branches =~ regex) ? true : false)
        return result
      end

      def remote_exists?(remote)
        remotes = `git remote`.strip.split(/\n/)
        remotes.include?(remote)
      end

      def check_for_jiveapps_remote(info)
        unless remote_exists?("jiveapps")
          run("git remote add jiveapps #{info['git_url']}")
          run("git branch --set-upstream master jiveapps/master")
        end
      end

      def watch_dir_and_commit_changes
        @dw = DirectoryWatcher.new '.', :glob => '**/*', :pre_load => true
        @dw.interval = 1
        @dw.add_observer do |*args| 
          verify_livedev_branch

          changes = ""
          args.each do |event|
            if event.type == :added || event.type == :modified
              run("git add #{event.path}")
            elsif event.type == :removed
              run("git rm #{event.path}")
            end
            display "  - [#{Time.now.strftime("%Y-%m-%d %T")}] LiveDev: #{event.type} #{event.path}"
            changes << "  #{event.type} '#{event.path}'\n"
          end

          run("git commit -m \"LiveDev Changes\n#{changes}\"")
          run("git push -f jiveapps #{livedev_branch_name}")
        end

        @dw.start

        while true do
          begin
            # for windows
            trap("INT") { prompt_to_quit_or_resume }
            input = gets.strip
            if ["exit", "quit", "\\q", ":q"].include?(input)
              prompt_to_quit_or_resume
            else
              display "Not a valid command. Type \"exit\" followed by [Enter] to quit."
            end
          rescue Interrupt # catch CTRL-C
            prompt_to_quit_or_resume
          end
        end

      end

      def prompt_to_quit_or_resume
        puts ""
        puts "Would you like to quit LiveDev mode now? y/n? "
        begin
          trap("INT") {}
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
