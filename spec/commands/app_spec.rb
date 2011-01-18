require 'spec_helper'

module Jiveapps::Command
  describe App do
    before(:each) do
      @cli = prepare_command(App)
    end

    describe "app list" do
      it "shows a list of apps" do
        @cli.stub!(:args).and_return([])
        @cli.jiveapps.should_receive(:list).and_return([{ 'name' => 'myapp' }, { 'name' => 'yourapp' }])
        @cli.should_receive(:display).with('Your apps:')
        @cli.should_receive(:display).with(["  - myapp", "  - yourapp"])
        @cli.list
      end

      it "shows 'You have no apps.' if the API returns an empty list" do
        @cli.stub!(:args).and_return([])
        @cli.jiveapps.should_receive(:list).and_return([])
        @cli.should_receive(:display).with('You have no apps.')
        @cli.list
      end

    end

    describe "app info" do
      it "shows info when name specified and rest client returns an app" do
        @cli.stub!(:args).and_return(['myapp'])
        @cli.jiveapps.should_receive(:info).with('myapp').and_return({ 
          'name' => 'myapp', 
          'app_url' => 'http://app_url',
          'git_url' => 'http://git_url' 
        })
        @cli.should_receive(:display).with('=== myapp')
        @cli.should_receive(:display).with("App URL:               http://app_url")
        @cli.should_receive(:display).with("Git URL:               http://git_url")
        @cli.info
      end

      it "shows 'App not found.' when name specified and rest client does not return an app" do
        @cli.jiveapps.should_receive(:info).with('myapp').and_return(nil)
        @cli.should_receive(:display).with('App not found.')
        @cli.info
      end

      it "shows app info using the --app syntax" do
        @cli.stub!(:args).and_return(['--app', 'myapp'])
        @cli.jiveapps.should_receive(:info).with('myapp').and_return({ :collaborators => [], :addons => []})
        @cli.info
      end

      it "shows app info reading app from current git dir" do
        @cli.stub!(:args).and_return([])
        @cli.stub!(:extract_app_in_dir).and_return('myapp')
        @cli.jiveapps.should_receive(:info).with('myapp').and_return({ :collaborators => [], :addons => []})
        @cli.info
      end

    end

  end
end
