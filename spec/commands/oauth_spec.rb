require 'spec_helper'

module Jiveapps::Command
  describe Oauth do
    before do
      @cli = prepare_command(Oauth)
    end

    it "lists oauth services" do
      @cli.jiveapps.should_receive(:list_oauth_services).and_return([])
      @cli.list
    end

    it "adds an oauth service if service name, key, and secret are supplied" do
      @cli.stub!(:args).and_return(['service_name', 'key', 'secret'])
      @cli.jiveapps.should_receive(:add_oauth_service).with('myapp', 'service_name', 'key', 'secret')
      @cli.jiveapps.should_receive(:list_oauth_services).and_return([])
      @cli.add
    end

    it "removes an oauth service if service name is supplied" do
      @cli.stub!(:args).and_return(['service_name'])
      @cli.stub!(:confirm).and_return(true)
      @cli.jiveapps.should_receive(:remove_oauth_service).with('myapp', 'service_name')
      @cli.jiveapps.should_receive(:list_oauth_services).and_return([])
      @cli.remove
    end
  end
end
