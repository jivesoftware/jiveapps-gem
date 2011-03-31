require 'spec_helper'

module Jiveapps::Command
  describe Livedev do
    before do
      @cli = prepare_command(Livedev)
      @cli.stub(:run) # stub run so git commands are not actually called
      @cli.jiveapps.stub(:user) { "testuser" }
      @cli.stub(:watch_dir_and_commit_changes)
      @cli.jiveapps.stub(:livedev)

      File.stub(:open).with(".git/livedev", 'w').and_return(true)

      @branch_name = 'livedev/testuser'
    end

    it "should name livedev branch name 'livedev/<username>'" do
      @cli.send(:branch_name).should == @branch_name
    end

    context "on" do

      before do
        @cli.jiveapps.stub(:info).and_return({})
      end

      it "should display 'App not found' if jiveapps.info lookup returns nil" do
        @cli.jiveapps.stub(:info).and_return(nil)
        @cli.should_receive(:display).with("App not found.")
        @cli.on
      end

      it "should display 'Starting LiveDev' if app exists" do
        @cli.should_receive(:display).with("=== Starting LiveDev: myapp")
        @cli.on
      end

      it "should check out the existing livedev branch if it exists" do
        Kernel.should_receive(:system).with("git show-ref --quiet --verify refs/heads/#{@branch_name}").and_return(true)
        @cli.should_receive(:run).with("git checkout #{@branch_name}")
        @cli.on
      end

      it "should check out a new livedev branch if it does not exists" do
        Kernel.should_receive(:system).with("git show-ref --quiet --verify refs/heads/#{@branch_name}").and_return(false)
        @cli.should_receive(:run).with("git checkout -b #{@branch_name}")
        @cli.on
      end

      it "should make rest call to turn livedev on if app exists" do
        @cli.jiveapps.should_receive(:livedev).with('myapp', 'on')
        @cli.on
      end

      it "should watch dir and commit changes when turned on" do
        @cli.should_receive(:watch_dir_and_commit_changes)
        @cli.on
      end

    end

    context "off" do
      before do
        @cli.stub(:`).and_return("") # stub backtick system command
      end

      it "should display 'Stopping LiveDev'" do
        @cli.should_receive(:display).with("\n\n\n=== Stopping LiveDev: myapp")
        @cli.off
      end

      it "should make rest call to turn livedev off" do
        @cli.jiveapps.should_receive(:livedev).with('myapp', 'off')
        @cli.off
      end

      it "should see if changes exist between livedev and master, and if so do a merge squash" do
        @cli.stub(:`).with("git diff #{@branch_name} master").and_return("differences")
        @cli.should_receive(:run).with("git merge #{@branch_name} --squash")
        @cli.off
      end

    end

  end
end
