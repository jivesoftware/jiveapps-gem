require 'spec_helper'

module Jiveapps::Command
  describe Sharing do
    before do
      @cli = prepare_command(Sharing)
    end

    it "lists collaborators" do
      @cli.jiveapps.should_receive(:list_collaborators).and_return([])
      @cli.list
    end

    it "adds collaborators with default access to view only" do
      @cli.stub!(:args).and_return(['joe_coworker'])
      @cli.jiveapps.should_receive(:add_collaborator).with('myapp', 'joe_coworker')
      @cli.add
    end

    it "removes collaborators" do
      @cli.stub!(:args).and_return(['joe_coworker'])
      @cli.jiveapps.should_receive(:remove_collaborator).with('myapp', 'joe_coworker')
      @cli.remove
    end

    # it "transfers ownership" do
    #   @cli.stub!(:args).and_return(['joe_coworker'])
    #   @cli.jiveapps.should_receive(:update).with('myapp', :transfer_owner => 'joe_coworker')
    #   @cli.transfer
    # end
  end
end
