require 'spec_helper'

module Jiveapps::Command
  describe Base do
    before do
      @args = [1, 2]
      @base = Base.new(@args)
      @base.stub!(:display)
      @client = mock('jiveapps client', :host => 'jiveapps.com', :git_host => 'jiveapps.com')
    end

    it "initializes the jiveapps client with the Auth command" do
      Jiveapps::Command.should_receive(:run_internal).with('auth:client', @args)
      @base.jiveapps
    end

    context "detecting the app" do
      before do
        @base.stub!(:jiveapps).and_return(@client)
      end

      it "attempts to find the app via the --app argument" do
        @base.stub!(:args).and_return(['--app', 'myapp'])
        @base.extract_app.should == 'myapp'
      end

      it "read remotes from git config" do
        File.stub!(:exists?).with('/home/dev/myapp/.git/config').and_return(true)
        File.stub!(:read).with('/home/dev/myapp/.git/config').and_return("
[core]
  repositoryformatversion = 0
  filemode = true
  bare = false
  logallrefupdates = true
[remote \"staging\"]
  url = git@jiveapps.com:myapp-staging.git
  fetch = +refs/heads/*:refs/remotes/staging/*
[remote \"production\"]
  url = git@jiveapps.com:myapp.git
  fetch = +refs/heads/*:refs/remotes/production/*
[remote \"github\"]
  url = git@github.com:myapp.git
  fetch = +refs/heads/*:refs/remotes/github/*
        ")
        @base.git_remotes('/home/dev/myapp').should == { 'staging' => 'myapp-staging', 'production' => 'myapp' }
      end

      it "attempts to find the git config file in parent folders" do
        File.should_receive(:exists?).with('/home/dev/myapp/app/models/.git/config').and_return(false)
        File.should_receive(:exists?).with('/home/dev/myapp/app/.git/config').and_return(false)
        File.should_receive(:exists?).with('/home/dev/myapp/.git/config').and_return(true)
        File.should_receive(:read).with('/home/dev/myapp/.git/config').and_return('')
        @base.git_remotes('/home/dev/myapp/app/models')
      end

      it "gets the app from remotes when there's only one app" do
        @base.stub!(:git_remotes).and_return({ 'jiveapps' => 'myapp' })
        @base.extract_app.should == 'myapp'
      end

      it "uses the remote named after the current folder name when there are multiple" do
        @base.stub!(:git_remotes).and_return({ 'staging' => 'myapp-staging', 'production' => 'myapp' })
        Dir.stub!(:pwd).and_return('/home/dev/myapp')
        @base.extract_app.should == 'myapp'
      end

      it "accepts a --remote argument to choose the app from the remote name" do
        @base.stub!(:git_remotes).and_return({ 'staging' => 'myapp-staging', 'production' => 'myapp' })
        @base.stub!(:args).and_return(['--remote', 'staging'])
        @base.extract_app.should == 'myapp-staging'
      end

      it "raises when cannot determine which app is it" do
        @base.stub!(:git_remotes).and_return({ 'staging' => 'myapp-staging', 'production' => 'myapp' })
        lambda { @base.extract_app }.should raise_error(Jiveapps::Command::CommandFailed)
      end
    end

    context "option parsing" do
      it "extracts options from args" do
        @base.stub!(:args).and_return(%w( a b --something value c d ))
        @base.extract_option('--something').should == 'value'
      end

      it "accepts options without value" do
        @base.stub!(:args).and_return(%w( a b --something))
        @base.extract_option('--something').should be_true
      end

      it "doesn't consider parameters as a value" do
        @base.stub!(:args).and_return(%w( a b --something --something-else c d))
        @base.extract_option('--something').should be_true
      end

      it "accepts a default value" do
        @base.stub!(:args).and_return(%w( a b --something))
        @base.extract_option('--something', 'default').should == 'default'
      end

      it "is not affected by multiple arguments with the same value" do
        @base.stub!(:args).and_return(%w( --arg1 val --arg2 val ))
        @base.extract_option('--arg1').should == 'val'
        @base.args.should == ['--arg2', 'val']
      end
    end

    describe "confirming" do
      it "confirms the app via --confirm" do
        @base.stub(:app).and_return("myapp")
        @base.stub(:args).and_return(["--confirm", "myapp"])
        @base.confirm_command.should be_true
      end

      it "does not confirms the app via --confirm on a mismatch" do
        @base.stub(:app).and_return("myapp")
        @base.stub(:args).and_return(["--confirm", "badapp"])
        lambda { @base.confirm_command}.should raise_error CommandFailed
      end

      it "confirms the app interactively via ask" do
        @base.stub(:app).and_return("myapp")
        @base.stub(:ask).and_return("myapp")
        @base.confirm_command.should be_true
      end

      it "fails if the interactive confirm doesn't match" do
        @base.stub(:app).and_return("myapp")
        @base.stub(:ask).and_return("badresponse")
        @base.confirm_command.should be_false
      end
    end

  end
end
