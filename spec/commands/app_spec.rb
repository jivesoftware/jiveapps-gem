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
        @cli.jiveapps.should_receive(:info).with('myapp').and_return({ 'name' => 'myapp' })
        @cli.should_receive(:display).with('=== myapp')
        @cli.should_receive(:display).with("Web URL: http://#{Jiveapps::HOSTNAME}/apps/myapp/app.xml")
        @cli.should_receive(:display).with("Git URL: git://#{Jiveapps::HOSTNAME}/myapp.git")
        @cli.info
      end

      it "shows 'App not found.' when name specified and rest client does not return an app" do
        @cli.stub!(:args).and_return(['invalid_app'])
        @cli.jiveapps.should_receive(:info).with('invalid_app').and_return(nil)
        @cli.should_receive(:display).with('App not found.')
        @cli.info
      end

      it "shows 'No app specified.' when no name specified" do
        @cli.stub!(:args).and_return([])
        @cli.jiveapps.should_not_receive(:info)
        @cli.should_receive(:display).with('No app specified.')
        @cli.should_receive(:display).with('Run this command from app folder or set it by running: jiveapps info <app name>')
        @cli.info
      end

    end

  end
end
